import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface AchievementRow {
  id: string;
  category: string;
  threshold_value: number | null;
}

interface CheckResult {
  newlyUnlocked: string[];
}

serve(async (req: Request) => {
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Client with service_role to insert user_achievements
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // Client with user's JWT to identify the caller
    const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser();

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const userId = user.id;

    // Parse optional run_session_id from request body
    let runSessionId: string | null = null;
    try {
      const body = await req.json();
      runSessionId = body.run_session_id ?? null;
    } catch {
      // No body is fine — check all achievements
    }

    // Fetch all achievements and user's already-unlocked ones
    const [achievementsRes, unlockedRes] = await Promise.all([
      adminClient.from("achievements").select("id, category, threshold_value"),
      adminClient
        .from("user_achievements")
        .select("achievement_id")
        .eq("user_id", userId),
    ]);

    if (achievementsRes.error) throw achievementsRes.error;
    if (unlockedRes.error) throw unlockedRes.error;

    const allAchievements: AchievementRow[] = achievementsRes.data;
    const alreadyUnlocked = new Set(
      (unlockedRes.data as { achievement_id: string }[]).map((r) => r.achievement_id)
    );

    const locked = allAchievements.filter((a) => !alreadyUnlocked.has(a.id));
    if (locked.length === 0) {
      return new Response(JSON.stringify({ newlyUnlocked: [] }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // Gather user stats
    const [userRes, streakRes, sessionRes] = await Promise.all([
      adminClient.from("users").select("total_distance_meters, total_cells_owned, team_id").eq("id", userId).single(),
      // Count consecutive run days ending today
      adminClient.rpc("calculate_streak", { p_user_id: userId }).single(),
      // Get the current session stats if provided
      runSessionId
        ? adminClient
            .from("run_sessions")
            .select("distance_meters, cells_captured, cells_overridden")
            .eq("id", runSessionId)
            .single()
        : Promise.resolve({ data: null, error: null }),
    ]);

    if (userRes.error) throw userRes.error;

    const userStats = userRes.data as {
      total_distance_meters: number;
      total_cells_owned: number;
      team_id: string | null;
    };

    const currentStreak: number = streakRes.error ? 0 : (streakRes.data as number) ?? 0;

    const sessionStats = sessionRes.data as {
      distance_meters: number;
      cells_captured: number;
      cells_overridden: number;
    } | null;

    // Check territory overrides for this user
    const overrideRes = await adminClient
      .from("territory_captures")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .eq("capture_type", "override");

    const overrideCount = overrideRes.count ?? 0;

    // Evaluate each locked achievement
    const newlyUnlocked: string[] = [];

    for (const achievement of locked) {
      const threshold = achievement.threshold_value ?? 0;
      let earned = false;

      switch (achievement.id) {
        // Territory achievements
        case "territory_first":
          earned = userStats.total_cells_owned >= threshold;
          break;
        case "territory_10":
        case "territory_100":
        case "territory_500":
        case "territory_1000":
          earned = userStats.total_cells_owned >= threshold;
          break;
        case "territory_override":
          earned = overrideCount >= threshold;
          break;

        // Streak achievements
        case "streak_3":
        case "streak_7":
        case "streak_14":
        case "streak_30":
        case "streak_100":
          earned = currentStreak >= threshold;
          break;

        // Cumulative distance achievements
        case "distance_10km":
        case "distance_50km":
        case "distance_100km":
        case "distance_500km":
        case "distance_1000km":
          earned = userStats.total_distance_meters >= threshold;
          break;

        // Single-run distance achievements
        case "distance_single_5km":
        case "distance_single_10km":
        case "distance_single_21km":
        case "distance_single_42km":
          if (sessionStats) {
            earned = sessionStats.distance_meters >= threshold;
          }
          // Also check historical best
          if (!earned) {
            const bestRes = await adminClient
              .from("run_sessions")
              .select("distance_meters")
              .eq("user_id", userId)
              .order("distance_meters", { ascending: false })
              .limit(1)
              .single();
            if (!bestRes.error && bestRes.data) {
              earned = (bestRes.data as { distance_meters: number }).distance_meters >= threshold;
            }
          }
          break;

        // Social achievements
        case "social_team_create":
          if (userStats.team_id) {
            const teamRes = await adminClient
              .from("teams")
              .select("created_by")
              .eq("id", userStats.team_id)
              .single();
            if (!teamRes.error && teamRes.data) {
              earned = (teamRes.data as { created_by: string }).created_by === userId;
            }
          }
          break;
        case "social_team_join":
          earned = userStats.team_id !== null;
          break;

        default:
          // Unknown achievement — use generic threshold check by category
          if (achievement.category === "territory") {
            earned = userStats.total_cells_owned >= threshold;
          } else if (achievement.category === "distance") {
            earned = userStats.total_distance_meters >= threshold;
          } else if (achievement.category === "streak") {
            earned = currentStreak >= threshold;
          }
          break;
      }

      if (earned) {
        newlyUnlocked.push(achievement.id);
      }
    }

    // Insert newly unlocked achievements
    if (newlyUnlocked.length > 0) {
      const rows = newlyUnlocked.map((achievementId) => ({
        user_id: userId,
        achievement_id: achievementId,
      }));

      const { error: insertError } = await adminClient
        .from("user_achievements")
        .upsert(rows, { onConflict: "user_id,achievement_id" });

      if (insertError) throw insertError;
    }

    const result: CheckResult = { newlyUnlocked };
    return new Response(JSON.stringify(result), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("check-achievements error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
