import Foundation
import SwiftData
import Supabase

@MainActor
@Observable
final class AnonymousModeViewModel {
    var isAnonymous: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCurrentState()
    }

    private func loadCurrentState() {
        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1
        if let profile = try? modelContext.fetch(descriptor).first {
            isAnonymous = profile.isAnonymous
        }
    }

    func toggleAnonymousMode(_ newValue: Bool) {
        isLoading = true
        errorMessage = nil

        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1
        guard let profile = try? modelContext.fetch(descriptor).first else {
            errorMessage = String(localized: "プロフィールが見つかりません")
            isLoading = false
            return
        }

        Task {
            do {
                try await updateAnonymousOnServer(userId: profile.id, isAnonymous: newValue)
                profile.isAnonymous = newValue
                isAnonymous = newValue
                try modelContext.save()
            } catch {
                errorMessage = String(localized: "設定の更新に失敗しました")
            }
            isLoading = false
        }
    }

    private func updateAnonymousOnServer(userId: String, isAnonymous: Bool) async throws {
        try await supabase
            .from("users")
            .update(["is_anonymous": isAnonymous])
            .eq("id", value: userId)
            .execute()
    }
}
