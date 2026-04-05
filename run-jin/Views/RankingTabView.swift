import SwiftUI

struct RankingTabView: View {
    var body: some View {
        Text("ランキング")
            .navigationTitle("ランキング")
    }
}

#Preview {
    NavigationStack {
        RankingTabView()
    }
}
