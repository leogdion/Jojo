//
//  DirectoryObserver.swift
//  JojoWatch Watch App
//
//  Created by Leo Dion on 1/13/23.
//

import Foundation
class FileObserver : ObservableObject {
  let fileURL : URL
  
  var dispatchSource : DispatchSourceFileSystemObject?
  var descriptor : Int32 = -1
  
  @Published var data : Data?
  
  func onFileWrite() {
    
      guard let data = try? Data(contentsOf: self.fileURL) else {
        return
      }
    Task{ @MainActor in
      self.data = data
    }
  }
  init (fileURL: URL) {
    
    self.fileURL = fileURL
  }
  
  func cancelHandler () {
    close(self.descriptor)
    self.dispatchSource = nil
    self.descriptor = -1
  }
  
  func stopMonitoring () {
    self.dispatchSource?.cancel()
  }
  
  func startMonitoring () {
    
    let descriptor = open(self.fileURL.path,O_EVTONLY)
    
    let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: .write, queue: .global(qos: .userInteractive))
    
    source.setCancelHandler(handler: self.cancelHandler)
    source.setEventHandler(handler: self.onFileWrite)
    
    self.descriptor = descriptor
    self.dispatchSource = source
    
    source.resume()
  }
}
