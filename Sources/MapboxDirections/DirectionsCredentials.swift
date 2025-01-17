import Foundation

/// The Mapbox access token specified in the main application bundle’s Info.plist.
let defaultAccessToken: String? =
    Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String ??
    Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken") as? String ??
    UserDefaults.standard.string(forKey: "MBXAccessToken")
let defaultApiEndPointURLString = Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAPIBaseURL") as? String

public struct DirectionsCredentials: Equatable {
    
    /**
    The mapbox access token. You can find this in your Mapbox account dashboard.
     */
    public let accessToken: String?
    
    /**
     The host to reach. defaults to `api.mapbox.com`.
     */
    public let host: URL
    
    /**
     The SKU Token associated with the request. Used for billing.
     */
    public var skuToken: String? {
        #if !os(Linux)
        guard let mbx: AnyClass = NSClassFromString("MBXAccounts"),
              mbx.responds(to: Selector(("serviceSkuToken"))),
              let serviceSkuToken = mbx.value(forKeyPath: "serviceSkuToken") as? String
        else { return nil }

        if mbx.responds(to: Selector(("serviceAccessToken"))) {
            guard let serviceAccessToken = mbx.value(forKeyPath: "serviceAccessToken") as? String,
                  serviceAccessToken == accessToken
            else { return nil }

            return serviceSkuToken
        }
        else {
            return serviceSkuToken
        }
        #else
        return nil
        #endif
    }
    
    /**
     Intialize a new credential.
     
     - parameter accessToken: Optional. An access token to provide. If this value is nil, the SDK will attempt to find a token from your app's `info.plist`.
     - parameter host: Optional. A parameter to pass a custom host. If `nil` is provided, the SDK will attempt to find a host from your app's `info.plist`, and barring that will default to  `https://api.mapbox.com`.
     */
    public init(accessToken token: String? = nil, host: URL? = nil) {
        let accessToken = token ?? defaultAccessToken
        
        precondition(accessToken != nil && !accessToken!.isEmpty, "A Mapbox access token is required. Go to <https://account.mapbox.com/access-tokens/>. In Info.plist, set the MBXAccessToken key to your access token, or use the Directions(accessToken:host:) initializer.")
        self.accessToken = accessToken
        if let host = host {
            self.host = host
        } else if let defaultHostString = defaultApiEndPointURLString, let defaultHost = URL(string: defaultHostString) {
            self.host = defaultHost
        } else {
            self.host = URL(string: "https://api.mapbox.com")!
        }
    }
}

