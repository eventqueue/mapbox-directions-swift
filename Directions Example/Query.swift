import Foundation

struct Query: Codable, Identifiable {
    let id: UUID
    var name: String
    var waypoints: [Waypoint]

    static func make() -> Query {
        return .init(id: .init(), name: UUID().uuidString, waypoints: .defaultWaypoints)
    }
}
