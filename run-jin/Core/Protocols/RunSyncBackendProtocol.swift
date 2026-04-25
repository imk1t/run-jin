import Foundation

/// `RunSyncService` が Supabase に対して行う通信を抽象化するプロトコル。
/// 本番は `SupabaseRunSyncBackend`、テストは `MockRunSyncBackend` を注入する。
protocol RunSyncBackendProtocol: Sendable {
    /// `submit-run` Edge Function を呼び出しセル情報付きでランをアップロード
    func invokeSubmitRun(_ request: SubmitRunRequestDTO) async throws -> SubmitRunResponseDTO

    /// `run_sessions` テーブルへ直接 upsert（セル無しランの場合）
    func upsertRunSession(_ dto: RunSessionDTO) async throws

    /// 認証済みの Supabase ユーザー ID を取得
    func currentUserId() async throws -> UUID
}
