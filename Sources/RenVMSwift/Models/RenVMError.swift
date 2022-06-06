import Foundation

public struct RenVMError: Swift.Error, Equatable, Decodable {
    public let message: String
    public let code: Int?
    
    public init(_ message: String) {
        self.message = message
        self.code = nil
    }
    
    public static var unauthorized: Self {
        .init("Unauthorized")
    }
    
    public static var unknown: Self {
        .init("Unknown")
    }
    
    public static var paramsMissing: Self {
        .init("One or some parameters are missing")
    }
    
    public static var invalidEndpoint: Self {
        .init("Invalid endpoint")
    }
}
