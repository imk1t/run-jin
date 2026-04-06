import MapKit
import SwiftData
import SwiftUI

struct RunningTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: RunningViewModel?
    @State private var showFinishConfirmation = false

    private let container = DependencyContainer.shared

    var body: some View {
        Group {
            if let viewModel {
                runningContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("ラン")
        .onAppear {
            if viewModel == nil {
                let service = container.runSessionService(modelContext: modelContext)
                viewModel = RunningViewModel(
                    runSessionService: service,
                    voiceFeedbackService: container.voiceFeedbackService
                )
            }
        }
    }

    @ViewBuilder
    private func runningContent(viewModel: RunningViewModel) -> some View {
        ZStack(alignment: .bottom) {
            // 地図
            Map(position: Binding(
                get: { viewModel.cameraPosition },
                set: { viewModel.cameraPosition = $0 }
            )) {
                UserAnnotation()

                if viewModel.routeCoordinates.count >= 2 {
                    MapPolyline(coordinates: viewModel.routeCoordinates)
                        .stroke(.blue, lineWidth: 4)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }

            // 統計オーバーレイ + コントロール
            VStack(spacing: 12) {
                statsOverlay(viewModel: viewModel)
                controlButtons(viewModel: viewModel)
            }
            .padding()

            // 画面ロックオーバーレイ
            if viewModel.isScreenLocked {
                ScreenLockOverlayView(
                    formattedDistance: viewModel.formattedDistance,
                    formattedDuration: viewModel.formattedDuration,
                    formattedPace: viewModel.formattedPace,
                    onUnlock: { viewModel.unlockScreen() }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isScreenLocked)
        .confirmationDialog(
            "ランニングを終了しますか？",
            isPresented: $showFinishConfirmation
        ) {
            Button("終了する", role: .destructive) {
                Task {
                    let _ = await viewModel.finishRun()
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .onChange(of: viewModel.stats.distanceMeters) {
            viewModel.checkKilometerMilestone()
        }
    }

    private func statsOverlay(viewModel: RunningViewModel) -> some View {
        HStack(spacing: 0) {
            statItem(value: viewModel.formattedDistance, unit: "km")
            Divider().frame(height: 40)
            statItem(value: viewModel.formattedDuration, unit: "時間")
            Divider().frame(height: 40)
            statItem(value: viewModel.formattedPace, unit: "/km")
            Divider().frame(height: 40)
            statItem(value: viewModel.formattedCalories, unit: "kcal")
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(value: String, unit: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func controlButtons(viewModel: RunningViewModel) -> some View {
        switch viewModel.state {
        case .idle:
            Button {
                Task { await viewModel.startRun() }
            } label: {
                Label("スタート", systemImage: "play.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

        case .running:
            HStack(spacing: 16) {
                Button {
                    viewModel.pauseRun()
                } label: {
                    Label("一時停止", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button {
                    viewModel.lockScreen()
                } label: {
                    Label("ロック", systemImage: "lock.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)

                Button {
                    showFinishConfirmation = true
                } label: {
                    Label("終了", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }

        case .paused:
            HStack(spacing: 16) {
                Button {
                    Task { await viewModel.resumeRun() }
                } label: {
                    Label("再開", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    showFinishConfirmation = true
                } label: {
                    Label("終了", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }

        case .finished:
            Button {
                Task { await viewModel.startRun() }
            } label: {
                Label("新しいランを開始", systemImage: "play.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }
}

#Preview {
    NavigationStack {
        RunningTabView()
    }
    .modelContainer(for: [RunSession.self, RunLocation.self], inMemory: true)
}
