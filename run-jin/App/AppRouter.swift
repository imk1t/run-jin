import SwiftUI

enum Route: Hashable {
    case runDetail(id: String)
    case runHistory
    case profile
    case teamDetail(id: String)
    case settings
    case privacyZones
    case anonymousMode
}

@Observable
final class AppRouter {
    var mapPath = NavigationPath()
    var runningPath = NavigationPath()
    var rankingPath = NavigationPath()
    var profilePath = NavigationPath()

    func navigate(to route: Route, tab: Tab) {
        switch tab {
        case .map:
            mapPath.append(route)
        case .running:
            runningPath.append(route)
        case .ranking:
            rankingPath.append(route)
        case .profile:
            profilePath.append(route)
        }
    }
}
