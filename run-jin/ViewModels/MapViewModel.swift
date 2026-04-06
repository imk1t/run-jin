import CoreLocation
import MapKit
import SwiftData
import SwiftUI

@MainActor
@Observable
final class MapViewModel {
    private let h3Service: H3ServiceProtocol

    var cameraPosition: MapCameraPosition = .userLocation(fallback: .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.68, longitude: 139.69),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    ))
    var visibleTerritories: [TerritoryOverlay] = []

    private var currentUserId: String?
    private var currentTeamId: String?

    init(h3Service: H3ServiceProtocol) {
        self.h3Service = h3Service
    }

    /// ユーザー情報を設定
    func setUser(userId: String?, teamId: String?) {
        self.currentUserId = userId
        self.currentTeamId = teamId
    }

    /// SwiftDataのTerritoryデータからオーバーレイを生成
    func updateOverlays(territories: [Territory]) {
        visibleTerritories = territories.compactMap { territory in
            guard let boundary = try? h3Service.boundary(for: territory.h3Index) else {
                return nil
            }
            let colorType = colorType(for: territory)
            return TerritoryOverlay(
                h3Index: territory.h3Index,
                coordinates: boundary,
                colorType: colorType
            )
        }
    }

    private func colorType(for territory: Territory) -> TerritoryColorType {
        if territory.ownerId == currentUserId {
            return .own
        }
        if let teamId = currentTeamId,
           territory.teamId == teamId {
            return .teammate
        }
        return .rival
    }
}

enum TerritoryColorType {
    case own       // 自分 = 青
    case teammate  // チームメイト = 水色
    case rival     // 他チーム = 赤

    var color: Color {
        switch self {
        case .own: .blue.opacity(0.3)
        case .teammate: .cyan.opacity(0.25)
        case .rival: .red.opacity(0.2)
        }
    }

    var strokeColor: Color {
        switch self {
        case .own: .blue.opacity(0.6)
        case .teammate: .cyan.opacity(0.5)
        case .rival: .red.opacity(0.4)
        }
    }
}

struct TerritoryOverlay: Identifiable {
    let id: String
    let coordinates: [CLLocationCoordinate2D]
    let colorType: TerritoryColorType

    init(h3Index: String, coordinates: [CLLocationCoordinate2D], colorType: TerritoryColorType) {
        self.id = h3Index
        self.coordinates = coordinates
        self.colorType = colorType
    }
}
