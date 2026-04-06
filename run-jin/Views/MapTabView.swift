import MapKit
import SwiftData
import SwiftUI

struct MapTabView: View {
    @Query private var territories: [Territory]
    @State private var viewModel: MapViewModel?

    private let h3Service = H3Service()
    private let locationService = DependencyContainer.shared.locationService

    var body: some View {
        Group {
            if let viewModel {
                territoryMap(viewModel: viewModel)
            } else {
                Map()
            }
        }
        .navigationTitle("マップ")
        .onAppear {
            locationService.requestWhenInUseAuthorization()
            if viewModel == nil {
                viewModel = MapViewModel(h3Service: h3Service)
            }
            viewModel?.updateOverlays(territories: territories)
        }
        .onChange(of: territories.count) {
            viewModel?.updateOverlays(territories: territories)
        }
    }

    @ViewBuilder
    private func territoryMap(viewModel: MapViewModel) -> some View {
        Map(position: Binding(
            get: { viewModel.cameraPosition },
            set: { viewModel.cameraPosition = $0 }
        )) {
            UserAnnotation()

            ForEach(viewModel.visibleTerritories) { overlay in
                MapPolygon(coordinates: overlay.coordinates)
                    .foregroundStyle(overlay.colorType.color)
                    .stroke(overlay.colorType.strokeColor, lineWidth: 1)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }
}

#Preview {
    NavigationStack {
        MapTabView()
    }
    .modelContainer(for: [Territory.self], inMemory: true)
}
