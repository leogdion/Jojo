import Foundation

public struct GetAppContainer : Subcommand {
  
  enum Error : Swift.Error {
    case missingData
    case invalidData(Data)
    case invalidPath(String)
  }
  let appBundleContainer : String
  let container: ContainerID
  let simulator : SimulatorID
  
  public typealias OutputType = URL
  
  public var arguments: [String] {
    return [
      "get_app_container",
      simulator.description,
      appBundleContainer,
      container.description
    ]
  }
  
  public func parse(_ data: Data?) throws -> URL {
    guard let data = data else {
      throw Error.missingData
    }
    
    guard let text = String(bytes: data, encoding: .utf8) else {
      throw Error.invalidData(data)
    }
    
    return URL(fileURLWithPath: text)
    
  }
}


