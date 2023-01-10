public struct Jojo {
    public private(set) var text = "Hello, World!"

    public init() {
    }
}

public struct SIWARequestBody: Codable {
  public let firstName: String?
  public let lastName: String?
  public let appleIdentityToken: String
}
