import MapKit
import SwiftUI

struct TerritoryRevealView: View {
    @State private var viewModel: TerritoryRevealViewModel
    @Environment(\.dismiss) private var dismiss

    init(captureResult: CaptureResult, h3Service: H3ServiceProtocol = H3Service()) {
        _viewModel = State(initialValue: TerritoryRevealViewModel(
            captureResult: captureResult,
            h3Service: h3Service
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            revealMap

            VStack(spacing: 12) {
                summaryBar
                actionButtons
            }
            .padding()
        }
        .navigationTitle("テリトリー獲得")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startReveal()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    // MARK: - Map

    @ViewBuilder
    private var revealMap: some View {
        Map {
            ForEach(viewModel.revealedOverlays) { overlay in
                MapPolygon(coordinates: overlay.coordinates)
                    .foregroundStyle(fillColor(for: overlay.type))
                    .stroke(strokeColor(for: overlay.type), lineWidth: 2)
            }
        }
        .mapStyle(.standard(elevation: .flat))
    }

    // MARK: - Summary Bar

    @ViewBuilder
    private var summaryBar: some View {
        HStack(spacing: 24) {
            if viewModel.newCaptureCount > 0 {
                Label {
                    Text("+\(viewModel.newCaptureCount) 新規")
                        .font(.headline)
                } icon: {
                    Image(systemName: "hexagon.fill")
                        .foregroundStyle(.blue)
                }
            }
            if viewModel.overrideCount > 0 {
                Label {
                    Text("+\(viewModel.overrideCount) 奪取")
                        .font(.headline)
                } icon: {
                    Image(systemName: "hexagon.fill")
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if viewModel.isComplete {
            Button {
                dismiss()
            } label: {
                Text("閉じる")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        } else if viewModel.isAnimating {
            Button {
                viewModel.skip()
            } label: {
                Text("スキップ")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Colors

    private func fillColor(for type: RevealCellType) -> Color {
        switch type {
        case .captured: .blue.opacity(0.35)
        case .overridden: .orange.opacity(0.35)
        }
    }

    private func strokeColor(for type: RevealCellType) -> Color {
        switch type {
        case .captured: .blue.opacity(0.8)
        case .overridden: .orange.opacity(0.8)
        }
    }
}

#Preview {
    NavigationStack {
        TerritoryRevealView(
            captureResult: CaptureResult(
                capturedCells: [],
                overriddenCells: [],
                failedCells: []
            )
        )
    }
}
