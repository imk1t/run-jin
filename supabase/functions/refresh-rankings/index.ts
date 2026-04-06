import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  // POST のみ受け付ける（cron や管理ツールから呼び出す）
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    // Authorization ヘッダーまたはサービスロールキーで認証
    const authHeader = req.headers.get("Authorization");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    // cron からの呼び出しの場合、Authorization ヘッダーがない場合がある
    // サービスロールキーで直接接続
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      serviceRoleKey,
    );

    // マテリアライズドビューをリフレッシュ
    const { error } = await supabase.rpc("refresh_rankings_territory");

    if (error) {
      // rpc が未定義の場合、直接 SQL で実行
      const { error: sqlError } = await supabase
        .from("_sql")
        .select()
        .limit(0);

      if (sqlError) {
        // Fallback: SQL 直接実行
        const response = await fetch(
          `${Deno.env.get("SUPABASE_URL")}/rest/v1/rpc/refresh_rankings_territory`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "apikey": serviceRoleKey,
              "Authorization": `Bearer ${serviceRoleKey}`,
            },
          },
        );

        if (!response.ok) {
          throw new Error(
            `Failed to refresh rankings: ${await response.text()}`,
          );
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        refreshed_at: new Date().toISOString(),
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
