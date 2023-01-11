//
//  ContentView.swift
//  JojoWatch Watch App
//
//  Created by Leo Dion on 1/10/23.
//

import SwiftUI

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

extension DirectoryObserver {
  convenience init() {
    self.init(directoryURL : FileManager.default.temporaryDirectory)
    
  }
}

struct ContentView: View {
  @StateObject var directoryObserver = DirectoryObserver()
  // xcrun simctl get_app_container booted com.BrightDigit.SimTest.watchkitapp data
  @State var text: String = ""
    var body: some View {
        VStack {
          TextField("Test", text: $text)
        Button("Paste") {
          let url = FileManager.default.temporaryDirectory.appending(component: "token")
          
          if let text = try? String(contentsOf: url) {
            Task {@MainActor in
              self.text = text
            }
          }
          }
        }
        .padding()
        .onReceive(self.directoryObserver.$fileURLs) { urls in
          
          guard let urls = urls else {
            return
          }
          var text : String? = nil
          
          for url in urls {
            
            let urlText : String
            do {
              urlText = try String(contentsOf: url)
            } catch {
              debugPrint(error)
              continue
            }
            text = urlText
            break
          }
          
          guard let text = text else {
            return
          }
          
          Task { @MainActor in
            self.text = text
          }
        }
        .onAppear{
          self.directoryObserver.startMonitoring()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
