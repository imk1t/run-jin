import SwiftUI

enum Tab: String, CaseIterable {
    case map
    case running
    case ranking
    case profile
}

struct TabBarView: View {
    @State private var selectedTab: Tab = .map

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.label, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        switch tab {
        case .map:
            NavigationStack {
                MapTabView()
            }
        case .running:
            NavigationStack {
                RunningTabView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            NavigationLink(value: Route.runHistory) {
                                Image(systemName: "list.bullet")
                            }
                        }
                    }
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .runHistory:
                            RunHistoryView()
                        case .runDetail(_):
                            Text("ラン詳細")
                        default:
                            EmptyView()
                        }
                    }
            }
        case .ranking:
            NavigationStack {
                RankingTabView()
            }
        case .profile:
            NavigationStack {
                ProfileTabView()
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .privacyZones:
                            PrivacyZoneListView()
                        default:
                            EmptyView()
                        }
                    }
            }
        }
    }
}

extension Tab {
    var label: String {
        switch self {
        case .map: String(localized: "マップ")
        case .running: String(localized: "ラン")
        case .ranking: String(localized: "ランキング")
        case .profile: String(localized: "プロフィール")
        }
    }

    var icon: String {
        switch self {
        case .map: "map.fill"
        case .running: "figure.run"
        case .ranking: "trophy.fill"
        case .profile: "person.fill"
        }
    }
}

#Preview {
    TabBarView()
}
