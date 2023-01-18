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
    let device = list.devices.values
      .flatMap { $0    }
      .first{$0.state == "Booted"}
    guard let udid = device?.udid else {
      return
    }
    let path = try await sim.run(GetAppContainer(appBundleContainer: "com.meijer.mobile.ent.Meijer.release.prod", container: .app, simulator: .id(udid)))
    print(path)
  }
}
