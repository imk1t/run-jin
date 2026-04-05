import SwiftUI

struct ProfileTabView: View {
    var body: some View {
        Text("プロフィール")
            .navigationTitle("プロフィール")
    }
}

#Preview {
    NavigationStack {
        ProfileTabView()
    }
}
