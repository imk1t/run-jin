import SwiftUI

struct ScreenLockOverlayView: View {
    let formattedDistance: String
    let formattedDuration: String
    let formattedPace: String
    let onUnlock: () -> Void

    @State private var tapCount = 0
    @State private var tapResetTask: Task<Void, Never>?
    @State private var isLongPressing = false
    @State private var longPressProgress: CGFloat = 0
    @State private var longPressTask: Task<Void, Never>?
    @State private var showUnlockHint = true

    /// 長押しで解除するまでの秒数
    private let longPressDuration: TimeInterval = 3.0
    /// トリプルタップのリセット間隔
    private let tapResetInterval: TimeInterval = 1.0
    /// トリプルタップで解除
    private let requiredTaps = 3

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.6))

                Text("画面ロック中")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.8))

                VStack(spacing: 24) {
                    lockStatItem(value: formattedDistance, unit: "km")
                    lockStatItem(value: formattedDuration, unit: "")
                    lockStatItem(value: formattedPace, unit: "/km")
                }
                .padding(.vertical, 20)

                Spacer()

                if showUnlockHint {
                    Text("トリプルタップ または 3秒長押しで解除")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.bottom, 40)
                        .onAppear {
                            Task {
                                try? await Task.sleep(for: .seconds(5))
                                withAnimation { showUnlockHint = false }
                            }
                        }
                }

                // 長押しプログレス表示
                if isLongPressing {
                    ProgressView(value: longPressProgress)
                        .progressViewStyle(.linear)
                        .tint(.white)
                        .padding(.horizontal, 60)
                        .padding(.bottom, 40)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
        .onLongPressGesture(minimumDuration: longPressDuration, perform: {
            // 長押し完了 — 解除
            onUnlock()
        }, onPressingChanged: { pressing in
            handleLongPressChange(pressing)
        })
        .accessibilityLabel("画面ロック中。トリプルタップまたは3秒長押しで解除できます")
    }

    private func lockStatItem(value: String, unit: String) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text(value)
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            if !unit.isEmpty {
                Text(unit)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private func handleTap() {
        tapCount += 1
        tapResetTask?.cancel()

        if tapCount >= requiredTaps {
            tapCount = 0
            onUnlock()
            return
        }

        tapResetTask = Task {
            try? await Task.sleep(for: .seconds(tapResetInterval))
            tapCount = 0
        }
    }

    private func handleLongPressChange(_ pressing: Bool) {
        isLongPressing = pressing
        longPressTask?.cancel()

        if pressing {
            longPressProgress = 0
            longPressTask = Task {
                let steps = 30
                let stepDuration = longPressDuration / Double(steps)
                for i in 1...steps {
                    try? await Task.sleep(for: .seconds(stepDuration))
                    guard !Task.isCancelled else { return }
                    withAnimation(.linear(duration: stepDuration)) {
                        longPressProgress = CGFloat(i) / CGFloat(steps)
                    }
                }
            }
        } else {
            withAnimation {
                longPressProgress = 0
            }
        }
    }
}

#Preview {
    ScreenLockOverlayView(
        formattedDistance: "3.25",
        formattedDuration: "18:42",
        formattedPace: "5:30",
        onUnlock: {}
    )
}
