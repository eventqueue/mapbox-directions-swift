import Foundation

/**
 Attributes are metadata information for a route leg.
 
 When any of the attributes are specified, the resulting route leg contains one attribute value for each segment in leg, where a segment is the straight line between two coordinates in the route leg’s full geometry.
 */
public struct AttributeOptions: OptionSet, CustomStringConvertible {
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /**
     Distance (in meters) along the segment.
     
     When this attribute is specified, the `RouteLeg.segmentDistances` property contains one value for each segment in the leg’s full geometry.
     */
    public static let distance = AttributeOptions(rawValue: 1 << 1)
    
    /**
     Expected travel time (in seconds) along the segment.
     
     When this attribute is specified, the `RouteLeg.expectedSegmentTravelTimes` property contains one value for each segment in the leg’s full geometry.
     */
    public static let expectedTravelTime = AttributeOptions(rawValue: 1 << 2)

    /**
     Current average speed (in meters per second) along the segment.
     
     When this attribute is specified, the `RouteLeg.segmentSpeeds` property contains one value for each segment in the leg’s full geometry.
     */
    public static let speed = AttributeOptions(rawValue: 1 << 3)
    
    /**
     Traffic congestion level along the segment.
     
     When this attribute is specified, the `RouteLeg.congestionLevels` property contains one value for each segment in the leg’s full geometry.
     
     This attribute requires `DirectionsProfileIdentifier.automobileAvoidingTraffic`. Any other profile identifier produces `CongestionLevel.unknown` for each segment along the route.
     */
    public static let congestionLevel = AttributeOptions(rawValue: 1 << 4)
    
    /**
     The maximum speed limit along the segment.
     
     When this attribute is specified, the `RouteLeg.segmentMaximumSpeedLimits` property contains one value for each segment in the leg’s full geometry.
     */
    public static let maximumSpeedLimit = AttributeOptions(rawValue: 1 << 5)

    /**
     Traffic congestion level in numeric form.

     When this attribute is specified, the `RouteLeg.numericCongestionLevels` property contains one value for each segment in the leg’s full geometry.

     This attribute requires `DirectionsProfileIdentifier.automobileAvoidingTraffic`. Any other profile identifier produces `nil` for each segment along the route.
     */
    public static let numericCongestionLevel = AttributeOptions(rawValue: 1 << 6)
    
    /**
     Creates an AttributeOptions from the given description strings.
     */
    public init?(descriptions: [String]) {
        var attributeOptions: AttributeOptions = []
        for description in descriptions {
            switch description {
            case "distance":
                attributeOptions.update(with: .distance)
            case "duration":
                attributeOptions.update(with: .expectedTravelTime)
            case "speed":
                attributeOptions.update(with: .speed)
            case "congestion":
                attributeOptions.update(with: .congestionLevel)
            case "maxspeed":
                attributeOptions.update(with: .maximumSpeedLimit)
            case "congestion_numeric":
                attributeOptions.update(with: .numericCongestionLevel)
            case "":
                continue
            default:
                return nil
            }
        }
        self.init(rawValue: attributeOptions.rawValue)
    }
    
    public var description: String {
        var descriptions: [String] = []
        if contains(.distance) {
            descriptions.append("distance")
        }
        if contains(.expectedTravelTime) {
            descriptions.append("duration")
        }
        if contains(.speed) {
            descriptions.append("speed")
        }
        if contains(.congestionLevel) {
            descriptions.append("congestion")
        }
        if contains(.maximumSpeedLimit) {
            descriptions.append("maxspeed")
        }
        if contains(.numericCongestionLevel) {
            descriptions.append("congestion_numeric")
        }
        return descriptions.joined(separator: ",")
    }
}

extension AttributeOptions: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description.components(separatedBy: ",").filter { !$0.isEmpty })
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let descriptions = try container.decode([String].self)
        self = AttributeOptions(descriptions: descriptions)!
    }
}
