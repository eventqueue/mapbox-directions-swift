import Foundation
import SwiftUI
import Combine
import MapboxDirections

final class DirectionsViewModel: ObservableObject {
    @Published
    var routes: [Route] = []

    init() {

    }

    func loadRoutes(for waypoints: [Waypoint]) {
        let options = RouteOptions(waypoints: waypoints.map(\.native))
        print("Calculating route for \(options.waypoints)")
        options.includesSteps = true
        options.routeShapeResolution = .full
        options.attributeOptions = [.congestionLevel, .maximumSpeedLimit]

        Directions.shared.calculate(options) { (session, result) in
            switch result {
            case let .failure(error):
                print("Error calculating directions: \(error)")
            case let .success(response):
                self.routes = response.routes ?? []
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject
    var vm: DirectionsViewModel

    @State
    private var waypoints: [Waypoint] = .defaultWaypoints

    @State
    private var showRoutes: Bool = false

    var body: some View {
        VStack {
            WaypointsEditor(waypoints: $waypoints)
                .background(NavigationLink(
                                destination: RoutesView(routes: vm.routes),
                                isActive: .init(get: {
                                    !vm.routes.isEmpty
                                }, set: { isActive in
                                    if !isActive {
                                        vm.routes.removeAll()
                                    }
                                }),
                                label: {
                                    EmptyView()
                                })
                )
                .toolbar(content: {
                    Button("Calculate") {
                        vm.loadRoutes(for: waypoints)
                    }
                })
                .navigationTitle("Edit Route Waypoints")
        }
    }
}

private extension Array where Element == Waypoint {
    static var defaultWaypoints: Self {
        [
            .init(latitude: 38.9131752, longitude: -77.0324047, name: "Mapbox"),
            .init(latitude: 38.8906572, longitude: -77.0090701, name: "Capitol"),
            .init(latitude: 38.8977000, longitude: -77.0365000, name: "White House"),
        ]
    }
}
