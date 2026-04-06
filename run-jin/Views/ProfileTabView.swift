import SwiftUI

struct ProfileTabView: View {
    var body: some View {
        List {
            Section("設定") {
                NavigationLink(value: Route.privacyZones) {
                    Label("プライバシーゾーン", systemImage: "shield.fill")
                }
            }
        }
        .navigationTitle("プロフィール")
    }
}

#Preview {
    NavigationStack {
        ProfileTabView()
    }
}
