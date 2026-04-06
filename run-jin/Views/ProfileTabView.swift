import SwiftUI

struct ProfileTabView: View {
    var body: some View {
        List {
            Section("設定") {
                NavigationLink(value: Route.anonymousMode) {
                    Label("匿名モード", systemImage: "eye.slash.fill")
                }
            }
        }
        .navigationTitle("プロフィール")
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .anonymousMode:
                AnonymousModeView()
            default:
                EmptyView()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileTabView()
    }
}
