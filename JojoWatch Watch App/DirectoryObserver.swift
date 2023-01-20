//
//  DirectoryObserver.swift
//  JojoWatch Watch App
//
//  Created by Leo Dion on 1/13/23.
//

import Foundation
import Combine
import System
import os.log
class DirectoryObserver {
  public let directoryPath : FilePath
  private let logger = Logger()
  private var dispatchSource : DispatchSourceFileSystemObject?
  private var descriptor : FileDescriptor?
  
  let fileWriteSubject = PassthroughSubject<Void, Never>()
  
  func onFileWrite() {
    
    logger.info("[SimulatorServices] - changed detected at \(self.directoryPath)")
    fileWriteSubject.send()
  }
  
  init (directoryPath: String) {
    
    self.directoryPath = FilePath(directoryPath)
  }
  
  func cancelHandler () {
    try? self.descriptor?.close()
    self.dispatchSource = nil
    self.descriptor = nil
  }
  
  func stopMonitoring () {
    self.dispatchSource?.cancel()
  }
  
  func startMonitoring (triggerImmediately: Bool) throws {
    logger.info("[SimulatorServices] - Beginning to monitor \(self.directoryPath).")
    let descriptor = try FileDescriptor.open(self.directoryPath, .init(rawValue: O_EVTONLY))
    
    
    let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor.rawValue, eventMask: .write, queue: .global(qos: .userInteractive))
    
    source.setCancelHandler(handler: self.cancelHandler)
    source.setEventHandler(handler: self.onFileWrite)
    
    self.descriptor = descriptor
    self.dispatchSource = source
    
    source.resume()
    
    if (triggerImmediately) {
      self.onFileWrite()
    }
  }
  
  func directoryEventPublisher() -> AnyPublisher<Void, Never> {
    self.fileWriteSubject.eraseToAnyPublisher()
  }
}
