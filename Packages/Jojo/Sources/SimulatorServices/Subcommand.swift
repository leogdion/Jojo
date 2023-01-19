import Foundation
public protocol Subcommand {
  associatedtype OutputType
  
  var arguments : [String] { get }
  func recover(_ error: Process.UncaughtSignalError) throws
  func parse(_ data: Data?) throws -> OutputType
}

public extension Subcommand {
  func recover(_ error: Process.UncaughtSignalError) throws {
    throw error
  }
}
