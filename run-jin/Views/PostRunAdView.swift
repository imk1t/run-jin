import SwiftUI

/// Full-screen interstitial-style ad shown after a run completes.
/// Non-premium users see this view; premium users skip it entirely.
struct PostRunAdView: View {
    /// Called when the user dismisses the ad (after the countdown expires).
    var onDismiss: () -> Void

    // MARK: - Private State

    @State private var remainingSeconds: Int = 5
    @State private var canClose: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Placeholder ad content area
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(width: 300, height: 250)

                    Text("広告")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Close / countdown button
                if canClose {
                    Button {
                        onDismiss()
                    } label: {
                        Text("閉じる")
                            .font(.headline)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(.white)
                            .foregroundStyle(.black)
                            .clipShape(Capsule())
                    }
                } else {
                    Text("\(remainingSeconds)秒後に閉じられます")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.bottom, 48)
        }
        .task {
            await startCountdown()
        }
    }

    // MARK: - Private

    private func startCountdown() async {
        for _ in 0..<5 {
            try? await Task.sleep(for: .seconds(1))
            remainingSeconds -= 1
        }
        canClose = true
    }
}

#Preview {
    PostRunAdView(onDismiss: {})
}
