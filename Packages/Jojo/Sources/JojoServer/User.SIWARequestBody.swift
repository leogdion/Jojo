import JojoModels

extension User {
  convenience init(body: SIWARequestBody, appleIdentityToken: String) {
    self.init(appleUserIdentifier: appleIdentityToken, firstName: body.firstName, lastName: body.lastName)
  }
  
  func patch(body: SIWARequestBody, appleIdentityToken: String) {
    self.lastName = body.lastName ?? self.lastName
    self.firstName = body.firstName ?? self.firstName
    self.email = body.email ?? self.email
    self.appleUserIdentifier = appleIdentityToken
  }
}
