
public struct SimulatorList : Decodable {
  let devicetypes : [DeviceType]
  let runtimes: [Runtime]
  let devices : [String : [Device]]
  let pairs : [String : DevicePair]
}


