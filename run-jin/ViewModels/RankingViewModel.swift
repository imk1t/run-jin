import Foundation
import Supabase

/// ランキングの表示範囲
enum RankingScope: String, CaseIterable, Sendable {
    case national
    case prefecture
    case municipality

    var label: String {
        switch self {
        case .national: String(localized: "全国")
        case .prefecture: String(localized: "都道府県")
        case .municipality: String(localized: "市区町村")
        }
    }
}

/// ランキングの期間フィルター
enum RankingPeriod: String, CaseIterable, Sendable {
    case weekly
    case monthly
    case allTime

    var label: String {
        switch self {
        case .weekly: String(localized: "週間")
        case .monthly: String(localized: "月間")
        case .allTime: String(localized: "累計")
        }
    }
}

@MainActor
@Observable
final class RankingViewModel {
    var rankings: [RankingEntryDTO] = []
    var selectedScope: RankingScope = .national
    var selectedPeriod: RankingPeriod = .allTime
    var isLoading = false
    var errorMessage: String?
    var currentUserId: UUID?

    /// 現在のユーザーのランキングエントリ
    var currentUserEntry: RankingEntryDTO? {
        guard let userId = currentUserId else { return nil }
        return rankings.first { $0.userId == userId }
    }

    /// 現在のユーザーの順位（表示スコープ内）
    var currentUserRank: Int? {
        guard let userId = currentUserId else { return nil }
        return rankings.firstIndex { $0.userId == userId }.map { $0 + 1 }
    }

    /// ランキングデータをSupabaseから取得
    func fetchRankings() async {
        isLoading = true
        errorMessage = nil

        do {
            // 現在のユーザーIDを取得
            if currentUserId == nil {
                let session = try await supabase.auth.session
                currentUserId = UUID(uuidString: session.user.id.uuidString)
            }

            var query = supabase
                .from("rankings_territory")
                .select()

            // スコープに応じたフィルタリング
            switch selectedScope {
            case .national:
                break // フィルターなし

            case .prefecture:
                if let prefectureCode = await currentUserPrefectureCode() {
                    query = query.eq("prefecture_code", value: prefectureCode)
                }

            case .municipality:
                if let municipalityCode = await currentUserMunicipalityCode() {
                    query = query.eq("municipality_code", value: municipalityCode)
                }
            }

            let entries: [RankingEntryDTO] = try await query
                .order("cells_owned", ascending: false)
                .limit(100)
                .execute()
                .value

            rankings = entries

        } catch {
            errorMessage = String(localized: "ランキングの取得に失敗しました")
        }

        isLoading = false
    }

    /// スコープ変更時にデータを再取得
    func onScopeChanged(_ scope: RankingScope) {
        selectedScope = scope
        Task {
            await fetchRankings()
        }
    }

    /// 期間変更時にデータを再取得
    func onPeriodChanged(_ period: RankingPeriod) {
        selectedPeriod = period
        Task {
            await fetchRankings()
        }
    }

    // MARK: - Private

    private func currentUserPrefectureCode() async -> Int? {
        guard let userId = currentUserId else { return nil }
        struct UserRegion: Decodable {
            let prefectureCode: Int?
            enum CodingKeys: String, CodingKey {
                case prefectureCode = "prefecture_code"
            }
        }
        let result: UserRegion? = try? await supabase
            .from("users")
            .select("prefecture_code")
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        return result?.prefectureCode
    }

    private func currentUserMunicipalityCode() async -> Int? {
        guard let userId = currentUserId else { return nil }
        struct UserRegion: Decodable {
            let municipalityCode: Int?
            enum CodingKeys: String, CodingKey {
                case municipalityCode = "municipality_code"
            }
        }
        let result: UserRegion? = try? await supabase
            .from("users")
            .select("municipality_code")
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        return result?.municipalityCode
    }
}
