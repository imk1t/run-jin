import Auth
import Foundation
import PhotosUI
import SwiftUI

@Observable
final class ProfileViewModel {
    var displayName: String = ""
    var selectedPrefectureCode: Int?
    var selectedMunicipalityCode: Int?
    var avatarURL: String?
    var totalDistanceMeters: Double = 0
    var totalCellsOwned: Int = 0
    var isPremium: Bool = false

    var isLoading: Bool = false
    var isSaving: Bool = false
    var errorMessage: String?
    var successMessage: String?
    var selectedPhotoItem: PhotosPickerItem?

    private let repository: any UserProfileRepositoryProtocol
    private let authService: any AuthServiceProtocol
    private var userId: String?

    init(
        repository: any UserProfileRepositoryProtocol = UserProfileRepository(),
        authService: any AuthServiceProtocol = AuthService()
    ) {
        self.repository = repository
        self.authService = authService
    }

    var totalDistanceKm: String {
        let km = totalDistanceMeters / 1000
        return String(format: "%.1f", km)
    }

    func loadProfile() async {
        guard let user = await authService.currentUser else { return }
        userId = user.id.uuidString
        isLoading = true
        errorMessage = nil
        do {
            let profile = try await repository.fetchProfile(userId: user.id.uuidString)
            displayName = profile.displayName
            selectedPrefectureCode = profile.prefectureCode
            selectedMunicipalityCode = profile.municipalityCode
            avatarURL = profile.avatarUrl
            totalDistanceMeters = profile.totalDistanceMeters
            totalCellsOwned = profile.totalCellsOwned
            isPremium = profile.isPremium
        } catch {
            errorMessage = String(localized: "プロフィールの読み込みに失敗しました。")
        }
        isLoading = false
    }

    func saveProfile() async {
        guard let userId else { return }
        isSaving = true
        errorMessage = nil
        successMessage = nil
        do {
            let update = UserProfileUpdateDTO(
                displayName: displayName,
                prefectureCode: selectedPrefectureCode,
                municipalityCode: selectedMunicipalityCode,
                avatarUrl: avatarURL
            )
            _ = try await repository.updateProfile(userId: userId, update: update)
            successMessage = String(localized: "プロフィールを保存しました。")
        } catch {
            errorMessage = String(localized: "プロフィールの保存に失敗しました。")
        }
        isSaving = false
    }

    func uploadAvatar(imageData: Data) async {
        guard let userId else { return }
        isSaving = true
        errorMessage = nil
        do {
            let url = try await repository.uploadAvatar(userId: userId, imageData: imageData)
            avatarURL = url
        } catch {
            errorMessage = String(localized: "アバターのアップロードに失敗しました。")
        }
        isSaving = false
    }

    func handlePhotoSelection() async {
        guard let item = selectedPhotoItem else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                await uploadAvatar(imageData: data)
            }
        } catch {
            errorMessage = String(localized: "画像の読み込みに失敗しました。")
        }
    }

    func signOut() async {
        do {
            try await authService.signOut()
        } catch {
            errorMessage = String(localized: "ログアウトに失敗しました。")
        }
    }
}
