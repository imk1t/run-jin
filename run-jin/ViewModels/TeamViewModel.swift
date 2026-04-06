import Foundation

@MainActor
@Observable
final class TeamViewModel {
    // MARK: - State

    var team: TeamDTO?
    var members: [TeamMemberDTO] = []
    var isLoading = false
    var errorMessage: String?

    // Create form
    var newTeamName = ""
    var newTeamColor = "#007AFF"

    // Join form
    var inviteCode = ""

    var hasTeam: Bool { team != nil }

    var totalTeamCells: Int {
        members.reduce(0) { $0 + $1.totalCellsOwned }
    }

    // MARK: - Dependencies

    private let repository: any TeamRepositoryProtocol

    nonisolated init(repository: any TeamRepositoryProtocol = TeamRepository()) {
        self.repository = repository
    }

    // MARK: - Actions

    func loadTeam(teamId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            team = try await repository.fetchTeam(id: teamId)
            if let team {
                members = try await repository.fetchMembers(teamId: team.id)
            }
        } catch {
            errorMessage = String(localized: "チーム情報の取得に失敗しました")
        }
        isLoading = false
    }

    func createTeam() async {
        guard !newTeamName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = String(localized: "チーム名を入力してください")
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let created = try await repository.createTeam(
                name: newTeamName.trimmingCharacters(in: .whitespaces),
                color: newTeamColor
            )
            try await repository.joinTeam(teamId: created.id)
            team = created
            members = try await repository.fetchMembers(teamId: created.id)
            newTeamName = ""
        } catch {
            errorMessage = String(localized: "チームの作成に失敗しました")
        }
        isLoading = false
    }

    func joinTeamWithInviteCode() async {
        guard !inviteCode.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = String(localized: "招待コードを入力してください")
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let found = try await repository.fetchTeamByInviteCode(
                inviteCode.trimmingCharacters(in: .whitespaces)
            )
            try await repository.joinTeam(teamId: found.id)
            team = found
            members = try await repository.fetchMembers(teamId: found.id)
            inviteCode = ""
        } catch {
            errorMessage = String(localized: "チームへの参加に失敗しました。招待コードを確認してください")
        }
        isLoading = false
    }

    func leaveTeam() async {
        isLoading = true
        errorMessage = nil
        do {
            try await repository.leaveTeam()
            team = nil
            members = []
        } catch {
            errorMessage = String(localized: "チームの退出に失敗しました")
        }
        isLoading = false
    }
}
