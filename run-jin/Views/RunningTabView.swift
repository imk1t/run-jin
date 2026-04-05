import SwiftUI

struct RunningTabView: View {
    var body: some View {
        VStack {
            Text("ランニングを始めましょう")
                .font(.title2)
        }
        .navigationTitle("ラン")
    }
}

#Preview {
    NavigationStack {
        RunningTabView()
    }
}
