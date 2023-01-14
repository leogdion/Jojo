//
//  ContentView.swift
//  JojoWatch Watch App
//
//  Created by Leo Dion on 1/10/23.
//

import SwiftUI
import JojoModels
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
  @State var accessToken: String?
    var body: some View {
        VStack {
          
          Button("Sign In With Apple") {
            debugPrint("LoggingIn")
//            Task {
//              var urlRequest = URLRequest(url: URL(string: "http://localhost:8080/users")!)
//              urlRequest.httpMethod = "POST"
//              urlRequest.httpBody = try! JSONEncoder().encode(body)
//              let userResponse : UserResponse
//              do {
//                let (data, _) = try await URLSession.shared.data(for: urlRequest)
//                userResponse = try JSONDecoder().decode(UserResponse.self, from: data)
//              } catch {
//                debugPrint(error)
//                return
//              }
//              Task { @MainActor in
//                self.accessToken = userResponse.accessToken
//              }
//            }
          }.disabled(self.accessToken == nil)
        }
        .padding()
        .onReceive(self.directoryObserver.$fileURLs) { urls in
          
          guard let urls = urls else {
            return
          }
          var text : Data? = nil
          
          for url in urls {
            
            let urlText : Data
            do {
              urlText = try Data(contentsOf: url)
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
          
          Task {
            var urlRequest = URLRequest(url: URL(string: "http://localhost:8080/users")!)
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = text
            
            urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")  // the request is JSON
            urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")        // the expected
            let userResponse : UserResponse
            do {
              let (data, _) = try await URLSession.shared.data(for: urlRequest)
              userResponse = try JSONDecoder().decode(UserResponse.self, from: data)
            } catch {
              debugPrint(error)
              return
            }
            Task { @MainActor in
              self.accessToken = userResponse.accessToken
              self.directoryObserver.stopMonitoring()
            }
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
