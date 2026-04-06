import Foundation
import Supabase

// MARK: - Protocol

protocol PrivacyZoneRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [PrivacyZoneDTO]
    func upsert(_ zone: PrivacyZoneDTO) async throws
    func delete(id: UUID) async throws
}

// MARK: - Supabase Implementation

final class PrivacyZoneRepository: PrivacyZoneRepositoryProtocol {
    private let tableName = "privacy_zones"

    func fetchAll() async throws -> [PrivacyZoneDTO] {
        try await supabase
            .from(tableName)
            .select()
            .execute()
            .value
    }

    func upsert(_ zone: PrivacyZoneDTO) async throws {
        try await supabase
            .from(tableName)
            .upsert(zone)
            .execute()
    }

    func delete(id: UUID) async throws {
        try await supabase
            .from(tableName)
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
