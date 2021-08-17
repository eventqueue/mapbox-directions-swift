
import Foundation
import MapboxDirections
import SwiftCLI


private let BogusCredentials = DirectionsCredentials(accessToken: "pk.feedCafeDadeDeadBeef-BadeBede.FadeCafeDadeDeed-BadeBede")
private let NotBogusCredentials = DirectionsCredentials()
private let directions = Directions(credentials: NotBogusCredentials)

class ProcessCommand<ResponceType : Codable, OptionsType : DirectionsOptions > : Command {
    
    // MARK: - Parameters
    
    var name = "process"
    
    @Key("-i", "--input", description: "[Optional] Filepath to the input JSON. If no filepath provided - will fall back to Directions API request using locations in config file.")
    var inputPath: String?
    
//    @Key("-l", "--locations", description: "[Optional] Location coordinates for Directions API reuqest if no filepath is provided. If no location coordinates provided - will fall back to a predefined route.")
//    var locationCoordinates: String?
    
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
            
            guard let routeResponse = routeResponse,
                  let routes = routeResponse.routes else { return }
            
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = .withInternetDateTime
            var time = Date()
            
            routes.forEach { route in
                let shape = route.shape
                let timeInterval = TimeInterval(route.distance/route.expectedTravelTime)
                for coord in shape!.coordinates {
                    gpxText.append("\n<wpt lat=\"\(coord.latitude)\" lon=\"\(coord.longitude)\">")
                    gpxText.append("\n\t<time> \(dateFormatter.string(from: time)) </time>")
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
    
    private func requestResponse(_ coordinates: [Waypoint]?) -> (Data?, Data) {
        let semaphore = DispatchSemaphore(value: 0)
        
        var waypoints: [Waypoint]
        if coordinates != nil {
            waypoints = coordinates!
        } else {
            waypoints = [
                Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.9131752, longitude: -77.0324047), name: "Mapbox"),
                Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.8977, longitude: -77.0365), name: "White House"),
            ]
        }
        
        let options = RouteOptions(waypoints: waypoints, profileIdentifier: .automobileAvoidingTraffic)
        options.includesSteps = true
        var responseData: Data?
        
        let url = directions.url(forCalculating: options)
        let urlSession = URLSession(configuration: .ephemeral)

        let task = urlSession.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil else {
                fatalError(error!.localizedDescription)
            }
            
            responseData = data
            print("Fetched data: \(data)")
            print("Fetched response: \(String(describing: response))")
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
        let encoder = JSONEncoder()
        let encodedOptions = try! encoder.encode(options)
        
        return (responseData, encodedOptions)
    }
    
    init(name: String, shortDescription: String = "") {
        self.name = name
        self.customShortDescription = shortDescription
    }
    
    // MARK: - Command implementation
    
    func execute() throws {
        guard let configPath = configPath else { exit(1) }
        
        let config = FileManager.default.contents(atPath: NSString(string: configPath).expandingTildeInPath)!
        let input: Data!
        
        let decoder = JSONDecoder()
        
        var directionsOptions: OptionsType!
        do {
            directionsOptions = try decoder.decode(OptionsType.self, from: config)
        } catch {
            print("Failed to decode input Options file.")
            print(error)
            exit(1)
        }
        
        if let inputPath = inputPath {
            input = FileManager.default.contents(atPath: NSString(string: inputPath).expandingTildeInPath)!
        } else {
            let response = requestResponse(directionsOptions.waypoints)
            input = response.0
        }
        
        decoder.userInfo = [.options: directionsOptions!,
                            .credentials: NotBogusCredentials]
        
        var routeResponse: RouteResponse?
        if outputFormat == .gpx {
            
            if let gpxData = input {
                routeResponse = try! decoder.decode(RouteResponse.self, from: gpxData)
            }
//            if let gpxData = try String(contentsOfFile: inputPath!).data(using: .utf8) {
//                routeResponse = try! decoder.decode(RouteResponse.self, from: gpxData)
//            }
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


