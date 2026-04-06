import MapKit
import SwiftData
import SwiftUI

struct RunDetailView: View {
    @State private var viewModel: RunDetailViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic

    init(session: RunSession) {
        let vm = RunDetailViewModel(session: session)
        _viewModel = State(initialValue: vm)
        _cameraPosition = State(initialValue: vm.mapCameraPosition)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // ルートマップ
                routeMap

                // 統計カード
                statsCard

                // スプリット
                if !viewModel.splits.isEmpty {
                    splitsSection
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.session.startedAt.formatted(.dateTime.month().day().weekday()))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var routeMap: some View {
        Map(position: $cameraPosition) {
            if viewModel.routeCoordinates.count >= 2 {
                MapPolyline(coordinates: viewModel.routeCoordinates)
                    .stroke(.blue, lineWidth: 4)
            }
            if let start = viewModel.routeCoordinates.first {
                Annotation("スタート", coordinate: start) {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(.green)
                }
            }
            if viewModel.routeCoordinates.count >= 2, let end = viewModel.routeCoordinates.last {
                Annotation("ゴール", coordinate: end) {
                    Image(systemName: "flag.checkered")
                        .foregroundStyle(.red)
                }
            }
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statsCard: some View {
        VStack(spacing: 12) {
            HStack {
                statBlock(title: "距離", value: viewModel.formattedDistance, unit: "km")
                Divider().frame(height: 40)
                statBlock(title: "時間", value: viewModel.formattedDuration, unit: "")
            }
            Divider()
            HStack {
                statBlock(title: "ペース", value: viewModel.formattedPace, unit: "/km")
                Divider().frame(height: 40)
                statBlock(title: "カロリー", value: viewModel.formattedCalories, unit: "kcal")
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func statBlock(title: LocalizedStringKey, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("スプリット")
                .font(.headline)

            ForEach(viewModel.splits) { split in
                HStack {
                    Text(split.label)
                        .font(.body)
                        .frame(width: 60, alignment: .leading)
                    ProgressView(value: min(1.0, normalizePace(split.paceSecondsPerKm)))
                        .tint(paceColor(split.paceSecondsPerKm))
                    Text(split.formattedPace)
                        .font(.body)
                        .monospacedDigit()
                        .frame(width: 60, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func normalizePace(_ pace: Double) -> Double {
        guard let avg = viewModel.session.avgPaceSecondsPerKm, avg > 0 else { return 0.5 }
        return avg / pace
    }

    private func paceColor(_ pace: Double) -> Color {
        guard let avg = viewModel.session.avgPaceSecondsPerKm else { return .blue }
        if pace < avg * 0.95 { return .green }
        if pace > avg * 1.05 { return .orange }
        return .blue
    }
}
