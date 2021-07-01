import Foundation
import func Polyline.encodeCoordinates
#if canImport(CoreLocation)
import typealias Polyline.LocationCoordinate2D
#else
import struct Polyline.LocationCoordinate2D
#endif
import Turf

extension LineString {
    /**
     Returns a string representation of the line string in [Polyline Algorithm Format](https://developers.google.com/maps/documentation/utilities/polylinealgorithm).
     */
    func polylineEncodedString(precision: Double = 1e5) -> String {
        #if canImport(CoreLocation)
        let coordinates = self.coordinates
        #else
        let coordinates = self.coordinates.map { Polyline.LocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        #endif
        return encodeCoordinates(coordinates, precision: precision)
    }
}

enum PolyLineString {
    case lineString(_ lineString: LineString)
    case polyline(_ encodedPolyline: String, precision: Double)
    
    init(lineString: LineString, shapeFormat: RouteShapeFormat) {
        switch shapeFormat {
        case .geoJSON:
            self = .lineString(lineString)
        case .polyline, .polyline6:
            let precision = shapeFormat == .polyline6 ? 1e6 : 1e5
            let encodedPolyline = lineString.polylineEncodedString(precision: precision)
            self = .polyline(encodedPolyline, precision: precision)
        }
    }
}

extension PolyLineString: Codable {
    private enum LineStringCodingKeys: String, CodingKey {
        case coordinates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let options = decoder.userInfo[.options] as? DirectionsOptions
        switch options?.shapeFormat ?? .default {
        case .geoJSON:
            let lineStringContainer = try decoder.container(keyedBy: LineStringCodingKeys.self)
            let coordinates = try lineStringContainer.decode([LocationCoordinate2DCodable].self, forKey: .coordinates).map { $0.decodedCoordinates }
            self = .lineString(LineString(coordinates))
        case .polyline, .polyline6:
            let precision = options?.shapeFormat == .polyline6 ? 1e6 : 1e5
            let encodedPolyline = try container.decode(String.self)
            self = .polyline(encodedPolyline, precision: precision)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .lineString(lineString):
            var lineStringContainer = encoder.container(keyedBy: LineStringCodingKeys.self)
            try lineStringContainer.encode(lineString.coordinates.map { LocationCoordinate2DCodable($0) }, forKey: .coordinates)
        case let .polyline(encodedPolyline, precision: _):
            try container.encode(encodedPolyline)
        }
    }
}

struct LocationCoordinate2DCodable: Codable {
    var latitude: Turf.LocationDegrees
    var longitude: Turf.LocationDegrees
    var decodedCoordinates: Turf.LocationCoordinate2D {
        return Turf.LocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(longitude)
        try container.encode(latitude)
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        longitude = try container.decode(Turf.LocationDegrees.self)
        latitude = try container.decode(Turf.LocationDegrees.self)
    }
    
    init(_ coordinate: Turf.LocationCoordinate2D) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }
}
