import SwiftUI
import UIKit

struct HealthKitSettingsView: View {
    private let healthKitService: HealthKitServiceProtocol
    @State private var status: HealthKitAuthorizationStatus
    @State private var isRequesting: Bool = false
    @State private var errorMessage: String?

    init(healthKitService: HealthKitServiceProtocol = DependencyContainer.shared.healthKitService) {
        self.healthKitService = healthKitService
        _status = State(initialValue: healthKitService.writeAuthorizationStatus)
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Label("ステータス", systemImage: "heart.text.square.fill")
                    Spacer()
                    Text(statusLabel)
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("ワークアウトの書き込み、心拍数と体重の読み込みに使用します。拒否してもランニングの記録は通常通り行えます。")
            }

            switch status {
            case .notDetermined:
                Section {
                    Button {
                        Task { await requestAuthorization() }
                    } label: {
                        HStack {
                            Spacer()
                            if isRequesting {
                                ProgressView()
                            } else {
                                Text("ヘルスケアへのアクセスを許可")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isRequesting)
                }
            case .sharingDenied:
                Section {
                    Button {
                        openSettings()
                    } label: {
                        Label("設定アプリで変更", systemImage: "gearshape.fill")
                    }
                } footer: {
                    Text("ヘルスケアへのアクセスが拒否されています。設定アプリから変更できます。")
                }
            case .sharingAuthorized:
                Section {
                    Label("許可済み", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            case .notAvailable:
                Section {
                    Label("このデバイスでは利用できません", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }

            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("ヘルスケア連携")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            healthKitService.refreshAuthorizationStatus()
            status = healthKitService.writeAuthorizationStatus
        }
    }

    private var statusLabel: LocalizedStringKey {
        switch status {
        case .notDetermined: "未設定"
        case .sharingAuthorized: "許可済み"
        case .sharingDenied: "拒否"
        case .notAvailable: "利用不可"
        }
    }

    private func requestAuthorization() async {
        isRequesting = true
        errorMessage = nil
        do {
            try await healthKitService.requestAuthorization()
            status = healthKitService.writeAuthorizationStatus
        } catch {
            errorMessage = error.localizedDescription
            status = healthKitService.writeAuthorizationStatus
        }
        isRequesting = false
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        HealthKitSettingsView()
    }
}
