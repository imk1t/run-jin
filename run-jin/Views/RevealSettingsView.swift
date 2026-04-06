import SwiftUI

/// Small settings sheet for territory reveal customization.
/// Currently supports toggling BGM on/off.
struct RevealSettingsView: View {
    @Binding var isBGMEnabled: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $isBGMEnabled) {
                        Label("BGM", systemImage: isBGMEnabled ? "speaker.wave.2" : "speaker.slash")
                    }
                } header: {
                    Text("サウンド")
                } footer: {
                    Text("テリトリー獲得演出時のBGMを切り替えます")
                }
            }
            .navigationTitle("演出設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    RevealSettingsView(isBGMEnabled: .constant(true))
}
