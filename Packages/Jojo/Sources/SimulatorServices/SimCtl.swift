//
//  File.swift
//  
//
//  Created by Leo Dion on 1/16/23.
//

import Foundation


public struct SimCtl {
  public init() {
  }
  
  let xcRunFileURL : URL = URL(fileURLWithPath: "/usr/bin/xcrun")
  
  public func run<SubcommandType: Subcommand>(_ subcommand: SubcommandType) async throws -> SubcommandType.OutputType {
    let process = Process()
    process.executableURL = xcRunFileURL
    process.arguments = ["simctl"] + subcommand.arguments
    print(process.arguments)
    let data : Data?
    do {
      data = try await process.run(timeout: .distantFuture)
    } catch let error as Process.UncaughtSignalError {
      try subcommand.recover(error)
      data = nil
    }
    return try subcommand.parse(data)
  }
  
}
