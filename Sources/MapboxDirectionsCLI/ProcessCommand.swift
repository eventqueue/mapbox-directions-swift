
import Foundation
import MapboxDirections
import SwiftCLI


private let BogusCredentials = DirectionsCredentials(accessToken: "pk.feedCafeDadeDeadBeef-BadeBede.FadeCafeDadeDeed-BadeBede")

class ProcessCommand<ResponceType : Codable, OptionsType : DirectionsOptions > : Command {
    
    // MARK: - Parameters
    
    var name = "process"
    
    @Key("-i", "--input", description: "Filepath to the input JSON.")
    var inputPath: String?
    
    @Key("-c", "--config", description: "Filepath to the JSON, containing serialized Options data.")
    var configPath: String?
    
    @Key("-o", "--output", description: "[Optional] Output filepath to save the conversion result. If no filepath provided - will output to the shell.")
    var outputPath: String?
    
    @Key("-f", "--format", description: "Output format. Supports `text`, `json`, and `gpx` formats. Defaults to `text`.")
    var outputFormat: OutputFormat?
    
    typealias RouteResponse = MapboxDirections.RouteResponse
    
    enum OutputFormat: String, ConvertibleFromString {
        case text
        case json
        case gpx
    }
    
    var customShortDescription: String = ""
    var shortDescription: String {
        return customShortDescription
    }
    
    // MARK: - Helper methods
    
    private func processResponse<T>(_ decoder: JSONDecoder, type: T.Type, from data: Data) throws -> Data where T : Codable {
        let result = try decoder.decode(type, from: data)
        let encoder = JSONEncoder()
        return try encoder.encode(result)
    }
    
    private func processOutput(_ data: Data, routeResponse: RouteResponse?) {
        var outputText: String = ""
        
        switch outputFormat {
        case .text, .none:
            outputText = String(data: data, encoding: .utf8)!
        case .json:
            if let object = try? JSONSerialization.jsonObject(with: data, options: []),
               let jsonData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]) {
                outputText = String(data: jsonData, encoding: .utf8)!
            }
        case .gpx:
            var gpxText: String = String("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
            gpxText.append("\n<gpx xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://www.topografix.com/GPX/1/1\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\" version=\"1.1\">")
            // do we need to include additional tags like metadata or the schema version?
            
            guard let routeResponse = routeResponse else { return }
            guard let routes = routeResponse.routes else { return }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            var time = Date()
            
            routes.forEach { route in
                let shape = route.shape
                let timeInterval = TimeInterval(route.distance/route.expectedTravelTime)
                for coord in shape!.coordinates {
                    gpxText.append("\n<wpt lat=\"\(coord.latitude)\" lon=\"\(coord.longitude)\">")
                    gpxText.append("\n\t<time> \(dateFormatter.string(from: time))Z </time>")
                    gpxText.append("\n</wpt>")
                    time.addTimeInterval(timeInterval)
                }
            }
            gpxText.append("\n</gpx>")
            outputText = gpxText
        }
        
        if let outputPath = outputPath {
            do {
                try outputText.write(toFile: NSString(string: outputPath).expandingTildeInPath,
                                     atomically: true,
                                     encoding: .utf8)
            } catch {
                print("Failed to save results to output file.")
                print(error)
                exit(1)
            }
        } else {
            print(outputText)
        }
    }
    
    init(name: String, shortDescription: String = "") {
        self.name = name
        self.customShortDescription = shortDescription
    }
    
    // MARK: - Command implementation
    
    func execute() throws {
        guard let inputPath = inputPath else { exit(1) }
        guard let configPath = configPath else { exit(1) }
        
        let input = FileManager.default.contents(atPath: NSString(string: inputPath).expandingTildeInPath)!
        let config = FileManager.default.contents(atPath: NSString(string: configPath).expandingTildeInPath)!
        
        let decoder = JSONDecoder()
        
        var directionsOptions: OptionsType!
        do {
            directionsOptions = try decoder.decode(OptionsType.self, from: config)
        } catch {
            print("Failed to decode input Options file.")
            print(error)
            exit(1)
        }
        
        decoder.userInfo = [.options: directionsOptions!,
                            .credentials: BogusCredentials]
        
        var routeResponse: RouteResponse!
        if outputFormat == .gpx {
            guard let gpxData = try String(contentsOfFile: inputPath).data(using: .utf8) else { exit(1)}
            routeResponse = try! decoder.decode(RouteResponse.self, from: gpxData)
        }
        
        var data: Data!
        do {
            data = try processResponse(decoder, type: ResponceType.self, from: input)
        } catch {
            print("Failed to decode input JSON file.")
            print(error)
            exit(1)
        }
        
        processOutput(data, routeResponse: routeResponse)
    }
}


