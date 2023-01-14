//
//  File.swift
//  
//
//  Created by Leo Dion on 1/13/23.
//

import Foundation
import JojoModels
import Vapor
extension UserResponse : Content {
  init(accessToken: String, user: User) {
    self.init(accessToken: accessToken, email: user.email, firstName: user.firstName, lastName: user.lastName)
  }
}
