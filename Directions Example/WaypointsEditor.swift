import Foundation
import SwiftUI
import CoreLocation
import MapboxDirections

struct Waypoint: Identifiable, Hashable {
    let id: UUID = UUID()
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    var name: String = ""

    var native: MapboxDirections.Waypoint {
        .init(coordinate: .init(latitude: latitude, longitude: longitude), name: name)
    }
}

struct WaypointsEditor: View {
    @Binding
    var waypoints: [Waypoint]

    var body: some View {
        List {
            ForEach(waypoints) { waypoint in
                HStack {
                    WaypointView(waypoint: .init(get: {
                        self.waypoints.first(where: { $0.id == waypoint.id })!
                    }, set: { newValue in
                        self.waypoints.firstIndex(of: waypoint).map {
                            waypoints[$0] = newValue
                        }
                    }))

                    Menu {
                        Button("Insert Above") {
                            addNewWaypoint(before: waypoint)
                        }
                        Button("Insert Below") {
                            addNewWaypoint(after: waypoint)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 30, height: 30, alignment: .center)
                    }
                }
            }
            .onMove { indices, newOffset in
                waypoints.move(fromOffsets: indices, toOffset: newOffset)
            }
            .onDelete { indexSet in
                waypoints.remove(atOffsets: indexSet)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.navigationBarLeading) {
                EditButton()
            }
        }
    }

    private func addNewWaypoint(after waypoint: Waypoint) {
        guard let waypointIndex = waypoints.firstIndex(of: waypoint) else {
            preconditionFailure("Waypoint is in the array of waypoints")
        }
        let insertionIndex = waypoints.index(after: waypointIndex)
        waypoints.insert(Waypoint(), at: insertionIndex)
    }
    private func addNewWaypoint(before waypoint: Waypoint) {
        guard let insertionIndex = waypoints.firstIndex(of: waypoint) else {
            preconditionFailure("Waypoint is in the array of waypoints")
        }
        waypoints.insert(Waypoint(), at: insertionIndex)
    }
}

struct WaypointView: View {
    @Binding
    var waypoint: Waypoint

    @State
    private var latitudeString: String

    @State
    private var longitudeString: String

    init(waypoint: Binding<Waypoint>) {
        _waypoint = waypoint
        _latitudeString = State<String>(initialValue: waypoint.wrappedValue.latitude.description)
        _longitudeString = .init(initialValue: waypoint.wrappedValue.longitude.description)
    }

    var body: some View {
        HStack {
            TextField("Name", text: $waypoint.name)
            TextField("Lat", text: $latitudeString, onEditingChanged: { _ in
                waypoint.latitude = .init(latitudeString) ?? 0
            })

            TextField("Lon", text: $longitudeString, onEditingChanged: { _ in
                waypoint.longitude = .init(longitudeString) ?? 0
            })
        }
    }
}
