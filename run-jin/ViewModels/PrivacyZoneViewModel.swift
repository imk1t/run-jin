import CoreLocation
import MapKit
import Supabase
import SwiftData
import SwiftUI

@MainActor
@Observable
final class PrivacyZoneViewModel {
    // MARK: - Public State

    var zones: [PrivacyZone] = []
    var isLoading = false
    var errorMessage: String?
    var showDeleteConfirmation = false

    // Edit state
    var editingZone: PrivacyZone?
    var editLabel = ""
    var editRadius: Double = 500
    var editCoordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671) // 東京駅デフォルト
    var editCameraPosition: MapCameraPosition = .automatic

    static let maxZones = 3
    static let minRadius: Double = 200
    static let maxRadius: Double = 1000

    // MARK: - Dependencies

    private let repository: PrivacyZoneRepositoryProtocol
    private let modelContext: ModelContext

    // MARK: - Init

    init(repository: PrivacyZoneRepositoryProtocol, modelContext: ModelContext) {
        self.repository = repository
        self.modelContext = modelContext
    }

    // MARK: - Computed

    var canAddZone: Bool {
        zones.count < Self.maxZones
    }

    var remainingZones: Int {
        max(0, Self.maxZones - zones.count)
    }

    // MARK: - CRUD

    func loadZones() async {
        isLoading = true
        errorMessage = nil

        // ローカルから読み込み
        let descriptor = FetchDescriptor<PrivacyZone>()
        if let localZones = try? modelContext.fetch(descriptor) {
            zones = localZones
        }

        // Supabaseから同期
        do {
            let remoteDTOs = try await repository.fetchAll()
            syncLocalWithRemote(remoteDTOs)
        } catch {
            errorMessage = String(localized: "プライバシーゾーンの読み込みに失敗しました")
        }

        isLoading = false
    }

    func prepareNewZone(at coordinate: CLLocationCoordinate2D? = nil) {
        editingZone = nil
        editLabel = ""
        editRadius = 500
        if let coordinate {
            editCoordinate = coordinate
        }
        editCameraPosition = .camera(MapCamera(
            centerCoordinate: editCoordinate,
            distance: 3000
        ))
    }

    func prepareEditZone(_ zone: PrivacyZone) {
        editingZone = zone
        editLabel = zone.label
        editRadius = Double(zone.radiusMeters)
        editCoordinate = CLLocationCoordinate2D(
            latitude: zone.centerLatitude,
            longitude: zone.centerLongitude
        )
        editCameraPosition = .camera(MapCamera(
            centerCoordinate: editCoordinate,
            distance: Double(zone.radiusMeters) * 6
        ))
    }

    func saveZone() async {
        errorMessage = nil

        let zone: PrivacyZone
        if let existing = editingZone {
            // 更新
            existing.label = editLabel
            existing.centerLatitude = editCoordinate.latitude
            existing.centerLongitude = editCoordinate.longitude
            existing.radiusMeters = Int(editRadius)
            zone = existing
        } else {
            // 新規作成
            guard canAddZone else {
                errorMessage = String(localized: "プライバシーゾーンは最大\(Self.maxZones)件までです")
                return
            }
            zone = PrivacyZone(
                label: editLabel,
                centerLatitude: editCoordinate.latitude,
                centerLongitude: editCoordinate.longitude,
                radiusMeters: Int(editRadius)
            )
            modelContext.insert(zone)
            zones.append(zone)
        }

        try? modelContext.save()

        // Supabaseへ同期
        do {
            let userId = try await currentUserId()
            let dto = PrivacyZoneDTO.from(zone: zone, userId: userId)
            try await repository.upsert(dto)
        } catch {
            errorMessage = String(localized: "保存に失敗しました。次回起動時に再同期します")
        }
    }

    func confirmDelete(_ zone: PrivacyZone) {
        editingZone = zone
        showDeleteConfirmation = true
    }

    func deleteZone() async {
        guard let zone = editingZone else { return }
        errorMessage = nil

        let zoneId = zone.id
        modelContext.delete(zone)
        zones.removeAll { $0.id == zoneId }
        try? modelContext.save()

        do {
            try await repository.delete(id: zoneId)
        } catch {
            errorMessage = String(localized: "削除の同期に失敗しました")
        }

        editingZone = nil
        showDeleteConfirmation = false
    }

    // MARK: - Private

    private func currentUserId() async throws -> UUID {
        let session = try await supabase.auth.session
        return session.user.id
    }

    private func syncLocalWithRemote(_ remoteDTOs: [PrivacyZoneDTO]) {
        let remoteIds = Set(remoteDTOs.map(\.id))
        let localIds = Set(zones.map(\.id))

        // リモートにあってローカルにないものを追加
        for dto in remoteDTOs where !localIds.contains(dto.id) {
            let zone = PrivacyZone(
                id: dto.id,
                label: dto.label,
                centerLatitude: dto.centerLatitude,
                centerLongitude: dto.centerLongitude,
                radiusMeters: dto.radiusMeters
            )
            modelContext.insert(zone)
            zones.append(zone)
        }

        // リモートから削除されたローカルデータを削除
        for zone in zones where !remoteIds.contains(zone.id) {
            modelContext.delete(zone)
        }
        zones.removeAll { !remoteIds.contains($0.id) }

        // リモートのデータでローカルを更新
        for dto in remoteDTOs {
            if let local = zones.first(where: { $0.id == dto.id }) {
                local.label = dto.label
                local.centerLatitude = dto.centerLatitude
                local.centerLongitude = dto.centerLongitude
                local.radiusMeters = dto.radiusMeters
            }
        }

        try? modelContext.save()
    }
}
