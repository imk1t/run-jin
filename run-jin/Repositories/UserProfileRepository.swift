import Foundation
import Supabase

final class UserProfileRepository: UserProfileRepositoryProtocol {
    nonisolated func fetchProfile(userId: String) async throws -> UserProfileDTO {
        try await supabase
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
    }

    nonisolated func updateProfile(userId: String, update: UserProfileUpdateDTO) async throws -> UserProfileDTO {
        try await supabase
            .from("users")
            .update(update)
            .eq("id", value: userId)
            .select()
            .single()
            .execute()
            .value
    }

    nonisolated func uploadAvatar(userId: String, imageData: Data) async throws -> String {
        let path = "avatars/\(userId).jpg"

        try await supabase.storage
            .from("avatars")
            .upload(
                path,
                data: imageData,
                options: .init(contentType: "image/jpeg", upsert: true)
            )

        let publicURL = try supabase.storage
            .from("avatars")
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }
}
