import Foundation

public struct GetAppContainer : Subcommand {
  
  enum Error : Swift.Error {
    case missingData
    case invalidData(Data)
    case invalidPath(String)
  }
  public let appBundleContainer : String
  public let container: ContainerID
  public let simulator : SimulatorID
  
  public init (
    appBundleContainer : String,
    container: ContainerID,
    simulator : SimulatorID
  ) {
    self.appBundleContainer = appBundleContainer
    self.container = container
    self.simulator = simulator
  }
  
  public typealias OutputType = Path
  
  public var arguments: [String] {
    return [
      "get_app_container",
      simulator.description,
      appBundleContainer,
      container.description
    ]
  }
  
  public func parse(_ data: Data?) throws -> Path {
    guard let data = data else {
      throw Error.missingData
    }
    
    guard let text = String(bytes: data, encoding: .utf8) else {
      throw Error.invalidData(data)
    }
    
    return text.trimmingCharacters(in: .whitespacesAndNewlines)
    
  }
}


