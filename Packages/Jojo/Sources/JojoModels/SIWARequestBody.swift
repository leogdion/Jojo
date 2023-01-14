public struct SIWARequestBody: Codable {
  public init(email: String? = nil, firstName: String? = nil, lastName: String? = nil, appleIdentityToken: String) {
    self.email = email
    self.firstName = firstName
    self.lastName = lastName
    self.appleIdentityToken = appleIdentityToken
  }
  
  public let email: String?
  public let firstName: String?
  public let lastName: String?
  public let appleIdentityToken: String
}
