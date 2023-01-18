//
//  File.swift
//  
//
//  Created by Leo Dion on 1/16/23.
//

import Foundation

public struct DevicePair : Decodable {
  public struct Device : Decodable {
    
  }
  let watch : Device
  let phone : Device
  let state : String
}


