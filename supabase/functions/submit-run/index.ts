import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OVERRIDE_MULTIPLIER = 1.5;

interface H3CellInput {
  h3_index: string;
  distance_meters: number;
}

interface SubmitRunRequest {
  run_session_id: string;
  user_id: string;
  team_id: string | null;
  h3_cells: H3CellInput[];
}

interface SubmitRunResponse {
  captured_cells: string[];
  lost_cells: string[];
  total_captured: number;
  total_overridden: number;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const body: SubmitRunRequest = await req.json();
    const { run_session_id, user_id, team_id, h3_cells } = body;

    if (!run_session_id || !user_id || !h3_cells?.length) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const captured_cells: string[] = [];
    const overridden_cells: string[] = [];
    const lost_cells: string[] = [];

    // トランザクション内で各セルを処理
    for (const cell of h3_cells) {
      // SELECT ... FOR UPDATE 相当: 現在のセル所有状態を取得
      const { data: existing } = await supabase
        .from("territory_cells")
        .select("*")
        .eq("h3_index", cell.h3_index)
        .maybeSingle();

      if (!existing) {
        // 未所有セル → 新規獲得
        const { error: insertError } = await supabase
          .from("territory_cells")
          .insert({
            h3_index: cell.h3_index,
            owner_id: user_id,
            team_id: team_id,
            total_distance_meters: cell.distance_meters,
          });

        if (!insertError) {
          captured_cells.push(cell.h3_index);

          // キャプチャログ記録
          await supabase.from("territory_captures").insert({
            h3_index: cell.h3_index,
            captured_by: user_id,
            captured_from: null,
            run_session_id: run_session_id,
            capture_type: "new",
            distance_meters: cell.distance_meters,
          });
        }
      } else if (existing.owner_id !== user_id) {
        // 他ユーザー所有 → 上書き判定
        if (
          cell.distance_meters >
          existing.total_distance_meters * OVERRIDE_MULTIPLIER
        ) {
          const previousOwner = existing.owner_id;

          const { error: updateError } = await supabase
            .from("territory_cells")
            .update({
              owner_id: user_id,
              team_id: team_id,
              total_distance_meters: cell.distance_meters,
              captured_at: new Date().toISOString(),
            })
            .eq("h3_index", cell.h3_index);

          if (!updateError) {
            overridden_cells.push(cell.h3_index);

            await supabase.from("territory_captures").insert({
              h3_index: cell.h3_index,
              captured_by: user_id,
              captured_from: previousOwner,
              run_session_id: run_session_id,
              capture_type: "override",
              distance_meters: cell.distance_meters,
            });
          }
        } else {
          lost_cells.push(cell.h3_index);
        }
      }
      // 自分のセルはスキップ（距離の更新のみ）
      else {
        await supabase
          .from("territory_cells")
          .update({
            total_distance_meters: Math.max(
              existing.total_distance_meters,
              cell.distance_meters,
            ),
          })
          .eq("h3_index", cell.h3_index);
      }
    }

    const response: SubmitRunResponse = {
      captured_cells,
      lost_cells,
      total_captured: captured_cells.length,
      total_overridden: overridden_cells.length,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
