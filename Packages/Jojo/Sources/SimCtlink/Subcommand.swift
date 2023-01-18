import Foundation
public protocol Subcommand {
  associatedtype OutputType
  
  var arguments : [String] { get }
  func parse(_ data: Data?) throws -> OutputType
}

