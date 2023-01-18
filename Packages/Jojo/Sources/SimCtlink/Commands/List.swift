import Foundation

public struct List : Subcommand {
  public init() {
  }
  
  public var arguments: [String] {
    return ["list", "-j"]
  }
  
  enum Error : Swift.Error {
    case missingData
    case deocdingError(DecodingError)
  }
  
  public func parse(_ data: Data?) throws -> SimulatorList {
    guard let data = data else {
      throw Error.missingData
    }
    
    do {
      return try decoder.decode(SimulatorList.self, from: data)
    } catch let error as DecodingError {
      throw Error.deocdingError(error)
    } catch {
      throw error
    }
  }
  
  public typealias OutputType = SimulatorList
  let decoder : JSONDecoder = JSONDecoder()
  
}


