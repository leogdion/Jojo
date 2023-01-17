//
//  File.swift
//  
//
//  Created by Leo Dion on 1/16/23.
//

import Foundation


extension Process : Sendable {
  struct UncaughtSignalError : Error {
    private init(reason: Process.TerminationReason, status: Int, data: Data?, output: Data?) {
      self.reason = reason
      self.status = status
      self.data = data
      self.output = output
    }
    
    internal init(reason: Process.TerminationReason, status: Int32, standardError : Pipe, standardOuput: Pipe) {
      let reason = reason
      let status = status
      let data = try? standardError.fileHandleForReading.readToEnd()
      let output = try? standardOuput.fileHandleForReading.readToEnd()
      self.init(reason: reason, status: Int(status), data: data, output: output)
    }
    
    let reason : TerminationReason
    let status : Int
    let data : Data?
    let output : Data?
  }
  func run ()  async throws -> Data? {
    let standardError = Pipe()
    let standardOutput = Pipe()
    
    self.standardError = standardError
    self.standardOutput = standardOutput
  
    
    return try await withCheckedThrowingContinuation { contination in
      self.terminationHandler = { _ in
        guard self.terminationReason == .exit, self.terminationStatus == 0 else {
          let error = UncaughtSignalError(
            reason: self.terminationReason,
            status: self.terminationStatus,
            standardError: standardError,
            standardOuput: standardOutput
          )
          contination.resume(with: .failure(error))
          return
        }
        let data : Data?
        do {
          data = try standardOutput.fileHandleForReading.readToEnd()
        } catch {
          contination.resume(with: .failure(error))
          return
        }
        contination.resume(with: .success(data))
      }
      do {
        try self.run()
      } catch {
        contination.resume(with: .failure(error))
      }
    }
  }
}

public protocol Subcommand {
  associatedtype OutputType
  
  var arguments : [String] { get }
  func parse(_ data: Data?) throws -> OutputType
}

public enum SimulatorID : CustomStringConvertible {
  public var description: String {
    switch self {
    case .booted :
      return "booted"
    case .id(let uuid):
      return uuid.uuidString
    }
  }
  
  case id(UUID)
  case booted
}

public enum ContainerID : CustomStringConvertible {
  case app     //            The .app bundle
  case data  //              The application's data container
  case groups    //          The App Group containers
  case appGroup(String) // A specific App Group container
  
  public var description: String {
    switch self {
    case .data:
      return "data"
    case .groups:
      return "groups"
    case .app:
      return "app"
    case .appGroup(let group):
      return group
    }
  }
}
public struct DeviceType : Decodable {
//  "productFamily" : "iPhone",
//  "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone SE (3rd generation).simdevicetype",
//  "maxRuntimeVersion" : 4294967295,
//  "maxRuntimeVersionString" : "65535.255.255",
//  "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation",
//  "modelIdentifier" : "iPhone14,6",
//  "minRuntimeVersionString" : "15.4.0",
//  "minRuntimeVersion" : 984064,
//  "name" : "iPhone SE (3rd generation)"
}

public struct Runtime : Decodable {
//  "bundlePath" : "\/Library\/Developer\/CoreSimulator\/Profiles\/Runtimes\/iOS 14.0.simruntime",
//        "buildversion" : "18A394",
//        "platform" : "iOS",
//        "runtimeRoot" : "\/Library\/Developer\/CoreSimulator\/Profiles\/Runtimes\/iOS 14.0.simruntime\/Contents\/Resources\/RuntimeRoot",
//        "identifier" : "com.apple.CoreSimulator.SimRuntime.iOS-14-0",
//        "version" : "14.0.1",
//        "isInternal" : false,
//        "isAvailable" : true,
//        "name" : "iOS 14.0",
//        "supportedDeviceTypes" : [
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone 6s.simdevicetype",
//            "name" : "iPhone 6s",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-6s",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone 6s Plus.simdevicetype",
//            "name" : "iPhone 6s Plus",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-6s-Plus",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone SE (1st generation).simdevicetype",
//            "name" : "iPhone SE (1st generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-SE",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone 7.simdevicetype",
//            "name" : "iPhone 7",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-7",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone 7 Plus.simdevicetype",
//            "name" : "iPhone 7 Plus",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-7-Plus",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone 8.simdevicetype",
//            "name" : "iPhone 8",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-8",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone 8 Plus.simdevicetype",
//            "name" : "iPhone 8 Plus",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-8-Plus",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone X.simdevicetype",
//            "name" : "iPhone X",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-X",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone Xs.simdevicetype",
//            "name" : "iPhone Xs",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-XS",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone Xs Max.simdevicetype",
//            "name" : "iPhone Xs Max",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-XS-Max",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone Xʀ.simdevicetype",
//            "name" : "iPhone Xʀ",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-XR",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone 11.simdevicetype",
//            "name" : "iPhone 11",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-11",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone 11 Pro.simdevicetype",
//            "name" : "iPhone 11 Pro",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-11-Pro",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone 11 Pro Max.simdevicetype",
//            "name" : "iPhone 11 Pro Max",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-11-Pro-Max",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPhone SE (2nd generation).simdevicetype",
//            "name" : "iPhone SE (2nd generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-SE--2nd-generation-",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPod touch (7th generation).simdevicetype",
//            "name" : "iPod touch (7th generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPod-touch--7th-generation-",
//            "productFamily" : "iPhone"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad mini 4.simdevicetype",
//            "name" : "iPad mini 4",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-mini-4",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad Air 2.simdevicetype",
//            "name" : "iPad Air 2",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Air-2",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad Pro (9.7-inch).simdevicetype",
//            "name" : "iPad Pro (9.7-inch)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro--9-7-inch-",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad Pro (12.9-inch) (1st generation).simdevicetype",
//            "name" : "iPad Pro (12.9-inch) (1st generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad (5th generation).simdevicetype",
//            "name" : "iPad (5th generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad--5th-generation-",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad Pro (12.9-inch) (2nd generation).simdevicetype",
//            "name" : "iPad Pro (12.9-inch) (2nd generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro--12-9-inch---2nd-generation-",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad Pro (10.5-inch).simdevicetype",
//            "name" : "iPad Pro (10.5-inch)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro--10-5-inch-",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad (6th generation).simdevicetype",
//            "name" : "iPad (6th generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad--6th-generation-",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad (7th generation).simdevicetype",
//            "name" : "iPad (7th generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad--7th-generation-",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad Pro (11-inch) (1st generation).simdevicetype",
//            "name" : "iPad Pro (11-inch) (1st generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro--11-inch-",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad Pro (12.9-inch) (3rd generation).simdevicetype",
//            "name" : "iPad Pro (12.9-inch) (3rd generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro--12-9-inch---3rd-generation-",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad Pro (11-inch) (2nd generation).simdevicetype",
//            "name" : "iPad Pro (11-inch) (2nd generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro--11-inch---2nd-generation-",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad Pro (12.9-inch) (4th generation).simdevicetype",
//            "name" : "iPad Pro (12.9-inch) (4th generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Pro--12-9-inch---4th-generation-",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad mini (5th generation).simdevicetype",
//            "name" : "iPad mini (5th generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-mini--5th-generation-",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad Air (3rd generation).simdevicetype",
//            "name" : "iPad Air (3rd generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Air--3rd-generation-",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad (8th generation).simdevicetype",
//            "name" : "iPad (8th generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad--8th-generation-",
//            "productFamily" : "iPad"
//          },
//          {
//            "bundlePath" : "\/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Library\/Developer\/CoreSimulator\/Profiles\/DeviceTypes\/iPad Air (4th generation).simdevicetype",
//            "name" : "iPad Air (4th generation)",
//            "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPad-Air--4th-generation-",
//            "productFamily" : "iPad"
//          }
//        ]
}

public struct Device : Decodable {
//  "com.apple.CoreSimulator.SimRuntime.iOS-16-0" : [
//        {
//          "lastBootedAt" : "2022-08-18T18:41:03Z",
//          "dataPath" : "\/Users\/leo\/Library\/Developer\/CoreSimulator\/Devices\/B1CD8B99-16E1-4841-BA5F-7C38776E41F6\/data",
//          "dataPathSize" : 1723662336,
//          "logPath" : "\/Users\/leo\/Library\/Logs\/CoreSimulator\/B1CD8B99-16E1-4841-BA5F-7C38776E41F6",
//          "udid" : "B1CD8B99-16E1-4841-BA5F-7C38776E41F6",
//          "isAvailable" : false,
//          "availabilityError" : "runtime profile not found",
//          "logPathSize" : 225280,
//          "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-13",
//          "state" : "Shutdown",
//          "name" : "iPhone 13"
//        },
//        {
//          "availabilityError" : "runtime profile not found",
//          "dataPath" : "\/Users\/leo\/Library\/Developer\/CoreSimulator\/Devices\/9F868F6D-5AD8-4400-A564-C85CAB6C18AD\/data",
//          "dataPathSize" : 13316096,
//          "logPath" : "\/Users\/leo\/Library\/Logs\/CoreSimulator\/9F868F6D-5AD8-4400-A564-C85CAB6C18AD",
//          "udid" : "9F868F6D-5AD8-4400-A564-C85CAB6C18AD",
//          "isAvailable" : false,
//          "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-14",
//          "state" : "Shutdown",
//          "name" : "iPhone 14"
//        },
//        {
//          "availabilityError" : "runtime profile not found",
//          "dataPath" : "\/Users\/leo\/Library\/Developer\/CoreSimulator\/Devices\/C04A9F86-5AD6-494A-B08C-653B837AAA15\/data",
//          "dataPathSize" : 13316096,
//          "logPath" : "\/Users\/leo\/Library\/Logs\/CoreSimulator\/C04A9F86-5AD6-494A-B08C-653B837AAA15",
//          "udid" : "C04A9F86-5AD6-494A-B08C-653B837AAA15",
//          "isAvailable" : false,
//          "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-14-Plus",
//          "state" : "Shutdown",
//          "name" : "iPhone 14 Plus"
//        },
//        {
//          "lastBootedAt" : "2022-10-04T17:49:02Z",
//          "dataPath" : "\/Users\/leo\/Library\/Developer\/CoreSimulator\/Devices\/8BC591AD-E779-4338-9BF8-D9C7F98B4324\/data",
//          "dataPathSize" : 826007552,
//          "logPath" : "\/Users\/leo\/Library\/Logs\/CoreSimulator\/8BC591AD-E779-4338-9BF8-D9C7F98B4324",
//          "udid" : "8BC591AD-E779-4338-9BF8-D9C7F98B4324",
//          "isAvailable" : false,
//          "availabilityError" : "runtime profile not found",
//          "logPathSize" : 53248,
//          "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-14-Pro",
//          "state" : "Shutdown",
//          "name" : "iPhone 14 Pro"
//        },
//        {
//          "availabilityError" : "runtime profile not found",
//          "dataPath" : "\/Users\/leo\/Library\/Developer\/CoreSimulator\/Devices\/B471A1F7-6154-4E4C-A00A-537343FC8565\/data",
//          "dataPathSize" : 13316096,
//          "logPath" : "\/Users\/leo\/Library\/Logs\/CoreSimulator\/B471A1F7-6154-4E4C-A00A-537343FC8565",
//          "udid" : "B471A1F7-6154-4E4C-A00A-537343FC8565",
//          "isAvailable" : false,
//          "deviceTypeIdentifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-14-Pro-Max",
//          "state" : "Shutdown",
//          "name" : "iPhone 14 Pro Max"
//        }
//      ],
}

public struct DevicePair : Decodable {
//  "F15E1A4E-51A0-4D9F-B683-673AB9388E3C" : {
//    "watch" : {
//      "name" : "Apple Watch Ultra (49mm)",
//      "udid" : "EA31C36A-B48B-48BD-B24B-C2B4C5734661",
//      "state" : "Shutdown"
//    },
//    "phone" : {
//      "name" : "iPhone 14 Pro Max",
//      "udid" : "23CA2740-5E81-437D-BD21-B0B75A1A758A",
//      "state" : "Shutdown"
//    },
//    "state" : "(active, disconnected)"
//  },
}
public struct SimulatorList : Decodable {
  let devicetypes : [DeviceType]
  let runtimes: [Runtime]
  let devices : [String : Device]
  let pairs : [UUID : DevicePair]
}
public struct List : Subcommand {
  public var arguments: [String] {
    return ["list", "-j"]
  }
  
  public func parse(_ data: Data?) throws -> SimulatorList {
    fatalError()
  }
  
  public typealias OutputType = SimulatorList
  
  
}
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

public struct Simctlink {
  let xcRunFileURL : URL = URL(fileURLWithPath: "/usr/bin/xcrun")
  
  func run<SubcommandType: Subcommand>(_ subcommand: SubcommandType) async throws -> SubcommandType.OutputType {
    let process = Process()
    process.executableURL = xcRunFileURL
    process.arguments = ["simctl"] + subcommand.arguments
    let data = try await process.run()
    return try subcommand.parse(data)
  }
  
  func run () throws -> String? {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = xcRunFileURL
    process.arguments = [
      "simctl",
      "get_app_container",
      "booted",
      "com.BrightDigit.Jojo.watchkitapp",
      "data"
    ]
    process.standardOutput = pipe
    try process.run()
    process.waitUntilExit()
    guard let data = try pipe.fileHandleForReading.readToEnd() else {
      return nil
    }
    
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
