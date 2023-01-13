import JWT

struct JWTToken: JWTPayload {
  let sub: SubjectClaim
  let exp: ExpirationClaim

  init(subject: String, expiresAt: Date) {
    sub = .init(value: subject)
    exp = .init(value: expiresAt)
  }

  func verify(using signer: JWTSigner) throws {
    
    try exp.verifyNotExpired()
  }
}
