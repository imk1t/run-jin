import Foundation
import Supabase

// MARK: - DTO

struct TeamDTO: Codable, Sendable {
    let id: String
    let name: String
    let color: String
    let inviteCode: String
    let memberCount: Int
    let totalCellsOwned: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case inviteCode = "invite_code"
        case memberCount = "member_count"
        case totalCellsOwned = "total_cells_owned"
    }
}

struct TeamMemberDTO: Codable, Sendable {
    let id: String
    let displayName: String
    let totalCellsOwned: Int

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case totalCellsOwned = "total_cells_owned"
    }
}

struct CreateTeamRequest: Codable, Sendable {
    let name: String
    let color: String

    enum CodingKeys: String, CodingKey {
        case name
        case color
    }
}

struct JoinTeamRequest: Codable, Sendable {
    let teamId: String

    enum CodingKeys: String, CodingKey {
        case teamId = "team_id"
    }
}

// MARK: - Protocol

protocol TeamRepositoryProtocol: Sendable {
    func fetchTeam(id: String) async throws -> TeamDTO
    func fetchTeamByInviteCode(_ code: String) async throws -> TeamDTO
    func createTeam(name: String, color: String) async throws -> TeamDTO
    func joinTeam(teamId: String) async throws
    func leaveTeam() async throws
    func fetchMembers(teamId: String) async throws -> [TeamMemberDTO]
}

// MARK: - Implementation

final class TeamRepository: TeamRepositoryProtocol {
    func fetchTeam(id: String) async throws -> TeamDTO {
        try await supabase
            .from("teams")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    func fetchTeamByInviteCode(_ code: String) async throws -> TeamDTO {
        try await supabase
            .from("teams")
            .select()
            .eq("invite_code", value: code)
            .single()
            .execute()
            .value
    }

    func createTeam(name: String, color: String) async throws -> TeamDTO {
        let request = CreateTeamRequest(name: name, color: color)
        return try await supabase
            .from("teams")
            .insert(request)
            .select()
            .single()
            .execute()
            .value
    }

    func joinTeam(teamId: String) async throws {
        let userId = try await supabase.auth.session.user.id.uuidString
        try await supabase
            .from("user_profiles")
            .update(JoinTeamRequest(teamId: teamId))
            .eq("id", value: userId)
            .execute()
    }

    func leaveTeam() async throws {
        let userId = try await supabase.auth.session.user.id.uuidString
        struct ClearTeam: Codable {
            let teamId: String?
            enum CodingKeys: String, CodingKey {
                case teamId = "team_id"
            }
        }
        try await supabase
            .from("user_profiles")
            .update(ClearTeam(teamId: nil))
            .eq("id", value: userId)
            .execute()
    }

    func fetchMembers(teamId: String) async throws -> [TeamMemberDTO] {
        try await supabase
            .from("user_profiles")
            .select("id, display_name, total_cells_owned")
            .eq("team_id", value: teamId)
            .execute()
            .value
    }
}
