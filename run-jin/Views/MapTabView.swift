import SwiftUI
import MapKit

struct MapTabView: View {
    var body: some View {
        Map()
            .navigationTitle("マップ")
    }
}

#Preview {
    NavigationStack {
        MapTabView()
    }
}
