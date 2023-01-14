//
//  DirectoryObserver.swift
//  JojoWatch Watch App
//
//  Created by Leo Dion on 1/13/23.
//

import Foundation
class DirectoryObserver : ObservableObject {
  let directoryURL : URL
  
  var dispatchSource : DispatchSourceFileSystemObject?
  var descriptor : Int32 = -1
  
  @Published var fileURLs : [URL]?
  
  func onFileWrite() {
    let urls = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.isRegularFileKey, .addedToDirectoryDateKey])
    Task{ @MainActor in
      self.fileURLs = urls
    }
  }
  init (directoryURL: URL) {
    
    self.directoryURL = directoryURL
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
    
    let descriptor = open(self.directoryURL.path,O_EVTONLY)
    
    let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: .write, queue: .global(qos: .userInteractive))
    
    source.setCancelHandler(handler: self.cancelHandler)
    source.setEventHandler(handler: self.onFileWrite)
    
    self.descriptor = descriptor
    self.dispatchSource = source
    
    source.resume()
  }
}
