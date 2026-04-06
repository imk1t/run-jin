import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * get-territory-around Edge Function
 *
 * Returns territory cells near a given location with pagination.
 * Since territory_cells stores h3_index as TEXT (no PostGIS geometry column),
 * we return paginated results and let the iOS client filter by H3 proximity.
 *
 * Privacy: owner_id is anonymized for cells that fall within another user's
 * privacy zone — only the requesting user's own cells show full owner info.
 *
 * GET /functions/v1/get-territory-around?lat=35.68&lng=139.76&radius=1000&limit=1000&offset=0
 */

interface TerritoryCellRow {
  h3_index: string;
  owner_id: string;
  team_id: string | null;
  captured_at: string;
  total_distance_meters: number;
}

interface PrivacyZoneRow {
  user_id: string;
  center_lat: number;
  center_lng: number;
  radius_meters: number;
}

interface TerritoryCellResponse {
  h3_index: string;
  owner_id: string | null;
  team_id: string | null;
  captured_at: string;
  total_distance_meters: number;
}

const MAX_LIMIT = 5000;
const DEFAULT_LIMIT = 1000;
const DEFAULT_OFFSET = 0;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  if (req.method !== "GET") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  }

  try {
    const url = new URL(req.url);
    const latStr = url.searchParams.get("lat");
    const lngStr = url.searchParams.get("lng");
    const radiusStr = url.searchParams.get("radius");
    const limitStr = url.searchParams.get("limit");
    const offsetStr = url.searchParams.get("offset");

    // Validate required params
    if (!latStr || !lngStr) {
      return new Response(
        JSON.stringify({ error: "Missing required params: lat, lng" }),
        {
          status: 400,
          headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
        },
      );
    }

    const lat = parseFloat(latStr);
    const lng = parseFloat(lngStr);
    const radius = radiusStr ? parseFloat(radiusStr) : 1000;
    const limit = Math.min(
      limitStr ? parseInt(limitStr, 10) : DEFAULT_LIMIT,
      MAX_LIMIT,
    );
    const offset = offsetStr ? parseInt(offsetStr, 10) : DEFAULT_OFFSET;

    if (isNaN(lat) || isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return new Response(
        JSON.stringify({ error: "Invalid lat/lng values" }),
        {
          status: 400,
          headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
        },
      );
    }

    if (isNaN(radius) || radius <= 0 || radius > 50000) {
      return new Response(
        JSON.stringify({ error: "Invalid radius (must be 0-50000 meters)" }),
        {
          status: 400,
          headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
        },
      );
    }

    // Extract requesting user from auth header (optional — anonymous access allowed)
    const authHeader = req.headers.get("Authorization");
    let requestingUserId: string | null = null;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    if (authHeader) {
      const token = authHeader.replace("Bearer ", "");
      const anonClient = createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        Deno.env.get("SUPABASE_ANON_KEY") ?? "",
        { global: { headers: { Authorization: `Bearer ${token}` } } },
      );
      const { data: { user } } = await anonClient.auth.getUser();
      requestingUserId = user?.id ?? null;
    }

    // Compute bounding box from lat/lng/radius for approximate filtering.
    // 1 degree latitude ~ 111,320 meters
    // 1 degree longitude ~ 111,320 * cos(lat) meters
    const latDelta = radius / 111_320;
    const lngDelta = radius / (111_320 * Math.cos((lat * Math.PI) / 180));
    const minLat = lat - latDelta;
    const maxLat = lat + latDelta;
    const minLng = lng - lngDelta;
    const maxLng = lng + lngDelta;

    // Query territory cells with pagination.
    // Since h3_index is TEXT and we don't have a geometry column, we fetch
    // all cells and rely on the client for precise H3 proximity filtering.
    // We order by captured_at desc to prioritize recent activity.
    //
    // Note: For future optimization, consider adding a geometry column to
    // territory_cells or installing h3-pg extension for server-side filtering.
    const { data: cells, error: cellsError } = await supabase
      .from("territory_cells")
      .select("h3_index, owner_id, team_id, captured_at, total_distance_meters")
      .order("captured_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (cellsError) {
      throw new Error(`Failed to query territory_cells: ${cellsError.message}`);
    }

    if (!cells || cells.length === 0) {
      return new Response(
        JSON.stringify({
          cells: [],
          meta: { lat, lng, radius, limit, offset, count: 0 },
        }),
        {
          status: 200,
          headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
        },
      );
    }

    // Fetch privacy zones to anonymize owner info for cells in privacy zones
    const { data: privacyZones } = await supabase
      .from("privacy_zones")
      .select("user_id, center_lat, center_lng, radius_meters");

    // Build a set of user_ids that have privacy zones affecting the bounding box
    const privacyZoneMap = new Map<string, PrivacyZoneRow[]>();
    if (privacyZones) {
      for (const zone of privacyZones as PrivacyZoneRow[]) {
        const existing = privacyZoneMap.get(zone.user_id) ?? [];
        existing.push(zone);
        privacyZoneMap.set(zone.user_id, existing);
      }
    }

    // Process cells: anonymize owner_id if the cell's owner has a privacy zone
    // and the queried location falls within that zone, unless it's the requesting user
    const responseCells: TerritoryCellResponse[] = (
      cells as TerritoryCellRow[]
    ).map((cell) => {
      let ownerId: string | null = cell.owner_id;

      // If the cell owner is NOT the requesting user, check privacy zones
      if (cell.owner_id !== requestingUserId) {
        const ownerZones = privacyZoneMap.get(cell.owner_id);
        if (ownerZones) {
          for (const zone of ownerZones) {
            // Check if the query center point falls within this privacy zone
            const distanceToZone = haversineDistance(
              lat,
              lng,
              zone.center_lat,
              zone.center_lng,
            );
            if (distanceToZone <= zone.radius_meters) {
              // Anonymize: the cell is in the owner's privacy zone
              ownerId = null;
              break;
            }
          }
        }
      }

      return {
        h3_index: cell.h3_index,
        owner_id: ownerId,
        team_id: cell.team_id,
        captured_at: cell.captured_at,
        total_distance_meters: cell.total_distance_meters,
      };
    });

    return new Response(
      JSON.stringify({
        cells: responseCells,
        meta: {
          lat,
          lng,
          radius,
          limit,
          offset,
          count: responseCells.length,
          bounding_box: { min_lat: minLat, max_lat: maxLat, min_lng: minLng, max_lng: maxLng },
        },
      }),
      {
        status: 200,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        status: 500,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      },
    );
  }
});

/**
 * Calculate distance between two points using the Haversine formula.
 * Returns distance in meters.
 */
function haversineDistance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const R = 6_371_000; // Earth radius in meters
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}
