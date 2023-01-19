//
//  File.swift
//  
//
//  Created by Leo Dion on 1/17/23.
//

import SimulatorServices
import Foundation
@main
struct Simulators {
  static func main() async throws {
    
    let sim = SimCtl()
    let paths : [Path]
    do {
      paths = try await withThrowingTaskGroup(of: Path?.self) { taskGroup in
        let list = try await sim.run(List())
        let devices = list.devices.values
          .flatMap { $0  }
          .filter{$0.state == "Booted"}
        for device in devices {
          taskGroup.addTask {
            do {
              return try await sim.run(GetAppContainer(appBundleContainer: "com.BrightDigit.Jojo.watchkitapp", container: .app, simulator: .id(device.udid)))
            } catch GetAppContainer.Error.missingData {
              return nil
            }
          }
        }
        
        return try await taskGroup.reduce(into: [Path?]()) { paths, path in
          paths.append(path)
        }.compactMap{$0}
      }
    } catch let error as Process.UncaughtSignalError {
      //let outputString = error.output.flatMap{String(data: $0, encoding: .utf8)}
      if let errorString = error.data.flatMap{String(data: $0, encoding: .utf8)} {
        //print(outputString)
        print(errorString)
      }
      return
    }
    
    print(paths)
    
    
  }
}
