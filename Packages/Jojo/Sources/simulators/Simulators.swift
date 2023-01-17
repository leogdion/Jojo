//
//  File.swift
//  
//
//  Created by Leo Dion on 1/17/23.
//

import Simctlink

@main
struct Simulators {
  static func main() async throws {
    let sim = Simctlink()
    let list = try await sim.run(List())
    dump(list)
  }
}
