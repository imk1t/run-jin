import CoreLocation
import SwiftUI

struct ShareSheetView: View {
    let session: RunSession
    @State private var selectedFormat: ShareImageFormat = .story
    @State private var generatedImage: UIImage?
    @State private var isGenerating = false
    @State private var showShareSheet = false
    @Environment(\.dismiss) private var dismiss

    private let generator = ShareImageGenerator()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // フォーマット選択
                formatPicker

                // プレビュー
                imagePreview

                // シェアボタン
                shareButton
            }
            .padding()
            .navigationTitle("シェア画像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .task {
                await generateImage()
            }
            .sheet(isPresented: $showShareSheet) {
                if let generatedImage {
                    ActivityViewController(activityItems: [generatedImage])
                }
            }
        }
    }

    private var formatPicker: some View {
        Picker("フォーマット", selection: $selectedFormat) {
            ForEach(ShareImageFormat.allCases) { format in
                Text(format.displayName).tag(format)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedFormat) {
            Task {
                await generateImage()
            }
        }
    }

    private var imagePreview: some View {
        Group {
            if isGenerating {
                ProgressView("画像を生成中...")
                    .frame(maxHeight: .infinity)
            } else if let generatedImage {
                Image(uiImage: generatedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
            } else {
                ContentUnavailableView(
                    "画像を生成できませんでした",
                    systemImage: "photo.badge.exclamationmark"
                )
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var shareButton: some View {
        Button {
            showShareSheet = true
        } label: {
            Label("シェアする", systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity)
                .padding()
                .background(generatedImage != nil ? Color.accentColor : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(generatedImage == nil || isGenerating)
    }

    private func generateImage() async {
        isGenerating = true
        defer { isGenerating = false }

        let coordinates = session.locations
            .sorted { $0.timestamp < $1.timestamp }
            .map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }

        let mapSize = CGSize(
            width: selectedFormat.size.width - 80,
            height: selectedFormat.size.height * (selectedFormat == .story ? 0.5 : 0.45)
        )

        let mapSnapshot = await generator.requestMapSnapshot(
            coordinates: coordinates,
            size: mapSize
        )

        generatedImage = await generator.generateImage(
            session: session,
            format: selectedFormat,
            mapSnapshot: mapSnapshot
        )
    }
}

/// UIActivityViewControllerのSwUIラッパー
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
