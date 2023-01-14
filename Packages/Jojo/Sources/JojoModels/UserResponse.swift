//
//  File.swift
//  
//
//  Created by Leo Dion on 1/13/23.
//

import Foundation

public struct UserResponse : Codable {
  public init(accessToken: String, email: String? = nil, firstName: String? = nil, lastName: String? = nil) {
    self.accessToken = accessToken
    self.email = email
    self.firstName = firstName
    self.lastName = lastName
  }
  
  public let accessToken : String
  public let email : String?
  public let firstName : String?
  public let lastName : String?
}

public struct UserInfoResponse : Codable {
  public init(email: String? = nil, firstName: String? = nil, lastName: String? = nil) {
    
    self.email = email
    self.firstName = firstName
    self.lastName = lastName
  }
  
  let email : String?
  let firstName : String?
  let lastName : String?
}
