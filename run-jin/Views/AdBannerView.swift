import SwiftUI

/// Placeholder banner ad view.
/// Replace with a `UIViewRepresentable` wrapping `GADBannerView` when AdMob is integrated.
struct AdBannerView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))

            Text("広告")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 50)
        .padding(.horizontal)
    }
}

#Preview {
    AdBannerView()
}
