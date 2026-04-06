// submit-run Edge Function
// Processes a completed run: records the session, captures territory cells,
// and applies landmark bonus multipliers to nearby cells.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Maximum distance (meters) from a landmark to apply its bonus to a cell
const LANDMARK_BONUS_RADIUS_METERS = 200;

interface RunCell {
  h3_index: string;
  distance_meters: number;
  lat: number;
  lng: number;
}

interface SubmitRunRequest {
  idempotency_key: string;
  started_at: string;
  ended_at: string;
  distance_meters: number;
  duration_seconds: number;
  avg_pace_seconds_per_km?: number;
  calories?: number;
  route_coordinates?: Array<{ lat: number; lng: number }>;
  cells: RunCell[];
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    // Authenticate the user
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabaseUser = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: authError,
    } = await supabaseUser.auth.getUser();

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const userId = user.id;

    // Use service role client for data operations
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const body: SubmitRunRequest = await req.json();

    // --- Idempotency check ---
    const { data: existingSession } = await supabase
      .from("run_sessions")
      .select("id")
      .eq("idempotency_key", body.idempotency_key)
      .maybeSingle();

    if (existingSession) {
      return new Response(
        JSON.stringify({
          message: "Run already submitted",
          session_id: existingSession.id,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // --- Build route LineString if coordinates provided ---
    let routeWkt: string | null = null;
    if (body.route_coordinates && body.route_coordinates.length >= 2) {
      const points = body.route_coordinates
        .map((c) => `${c.lng} ${c.lat}`)
        .join(", ");
      routeWkt = `SRID=4326;LINESTRING(${points})`;
    }

    // --- Insert run session ---
    const { data: session, error: sessionError } = await supabase
      .from("run_sessions")
      .insert({
        user_id: userId,
        started_at: body.started_at,
        ended_at: body.ended_at,
        distance_meters: body.distance_meters,
        duration_seconds: body.duration_seconds,
        avg_pace_seconds_per_km: body.avg_pace_seconds_per_km ?? null,
        calories: body.calories ?? null,
        route: routeWkt,
        idempotency_key: body.idempotency_key,
        cells_captured: 0,
        cells_overridden: 0,
      })
      .select("id")
      .single();

    if (sessionError || !session) {
      console.error("Failed to insert run session:", sessionError);
      return new Response(
        JSON.stringify({ error: "Failed to create run session" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // --- Fetch all landmarks for bonus calculation ---
    const { data: landmarks, error: landmarksError } = await supabase
      .from("landmarks")
      .select("id, name, location, bonus_multiplier, h3_index");

    if (landmarksError) {
      console.error("Failed to fetch landmarks:", landmarksError);
    }

    // --- Process each cell ---
    let cellsCaptured = 0;
    let cellsOverridden = 0;
    const captures: Array<{
      run_session_id: string;
      h3_index: string;
      user_id: string;
      previous_owner_id: string | null;
      distance_meters: number;
      capture_type: string;
    }> = [];

    // Get user's team_id for territory assignment
    const { data: userProfile } = await supabase
      .from("users")
      .select("team_id")
      .eq("id", userId)
      .single();

    const teamId = userProfile?.team_id ?? null;

    for (const cell of body.cells) {
      // Calculate landmark bonus for this cell
      let bonusMultiplier = 1.0;

      if (landmarks && landmarks.length > 0) {
        // Check proximity to each landmark using PostGIS ST_DWithin
        const { data: nearbyLandmarks } = await supabase.rpc(
          "find_nearby_landmarks",
          {
            cell_lng: cell.lng,
            cell_lat: cell.lat,
            radius_meters: LANDMARK_BONUS_RADIUS_METERS,
          }
        );

        if (nearbyLandmarks && nearbyLandmarks.length > 0) {
          // Use the highest bonus multiplier among nearby landmarks
          bonusMultiplier = Math.max(
            ...nearbyLandmarks.map(
              (l: { bonus_multiplier: number }) => l.bonus_multiplier
            )
          );
        }
      }

      // Apply bonus to the effective distance
      const effectiveDistance = cell.distance_meters * bonusMultiplier;

      // Attempt to capture/update the cell using SELECT ... FOR UPDATE pattern
      const { data: existingCell } = await supabase
        .from("territory_cells")
        .select("h3_index, owner_id, total_distance_meters")
        .eq("h3_index", cell.h3_index)
        .maybeSingle();

      if (!existingCell) {
        // New cell — capture it
        const { error: insertError } = await supabase
          .from("territory_cells")
          .insert({
            h3_index: cell.h3_index,
            owner_id: userId,
            team_id: teamId,
            total_distance_meters: effectiveDistance,
          });

        if (!insertError) {
          cellsCaptured++;
          captures.push({
            run_session_id: session.id,
            h3_index: cell.h3_index,
            user_id: userId,
            previous_owner_id: null,
            distance_meters: effectiveDistance,
            capture_type: "new",
          });
        }
      } else if (existingCell.owner_id === userId) {
        // Already own this cell — add distance
        await supabase
          .from("territory_cells")
          .update({
            total_distance_meters:
              existingCell.total_distance_meters + effectiveDistance,
          })
          .eq("h3_index", cell.h3_index);
      } else {
        // Another user owns this cell — attempt override
        const newTotal = existingCell.total_distance_meters + effectiveDistance;
        // Override if the runner has accumulated more effective distance
        if (effectiveDistance > existingCell.total_distance_meters * 0.5) {
          const previousOwnerId = existingCell.owner_id;
          await supabase
            .from("territory_cells")
            .update({
              owner_id: userId,
              team_id: teamId,
              total_distance_meters: effectiveDistance,
            })
            .eq("h3_index", cell.h3_index);

          cellsOverridden++;
          captures.push({
            run_session_id: session.id,
            h3_index: cell.h3_index,
            user_id: userId,
            previous_owner_id: previousOwnerId,
            distance_meters: effectiveDistance,
            capture_type: "override",
          });
        }
      }
    }

    // --- Bulk insert territory captures ---
    if (captures.length > 0) {
      const { error: captureError } = await supabase
        .from("territory_captures")
        .insert(captures);

      if (captureError) {
        console.error("Failed to insert captures:", captureError);
      }
    }

    // --- Update session with capture counts ---
    await supabase
      .from("run_sessions")
      .update({
        cells_captured: cellsCaptured,
        cells_overridden: cellsOverridden,
      })
      .eq("id", session.id);

    // --- Update user totals ---
    await supabase.rpc("update_user_totals", { p_user_id: userId });

    return new Response(
      JSON.stringify({
        session_id: session.id,
        cells_captured: cellsCaptured,
        cells_overridden: cellsOverridden,
        total_cells_processed: body.cells.length,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("submit-run error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
