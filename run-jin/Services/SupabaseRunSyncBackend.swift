import Foundation
import Supabase

/// 本番向け `RunSyncBackendProtocol` 実装。グローバル `supabase` クライアントを利用。
final class SupabaseRunSyncBackend: RunSyncBackendProtocol {
    func invokeSubmitRun(_ request: SubmitRunRequestDTO) async throws -> SubmitRunResponseDTO {
        try await supabase.functions.invoke(
            "submit-run",
            options: .init(body: request)
        )
    }

    func upsertRunSession(_ dto: RunSessionDTO) async throws {
        try await supabase
            .from("run_sessions")
            .upsert(dto, onConflict: "idempotency_key")
            .execute()
    }

    func currentUserId() async throws -> UUID {
        try await supabase.auth.session.user.id
    }
}
