import JojoModels

extension User {
  convenience init(body: SIWARequestBody) {
    self.init(appleUserIdentifier: body.appleIdentityToken, firstName: body.firstName, lastName: body.lastName)
  }
  
  func patch(body: SIWARequestBody) {
    self.lastName = body.lastName ?? self.lastName
    self.firstName = body.firstName ?? self.firstName
    self.email = body.email ?? self.email
    self.appleUserIdentifier = body.appleIdentityToken
  }
}
