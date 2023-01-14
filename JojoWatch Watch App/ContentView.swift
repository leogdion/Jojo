//
//  ContentView.swift
//  JojoWatch Watch App
//
//  Created by Leo Dion on 1/10/23.
//

import SwiftUI
import JojoModels
import Combine

class AuthenticationObject : ObservableObject {
  @Published var fileObserver : FileObserver
  @Published var userResponse: UserResponse?
  @Published var lastError : Error?
  init() {
    
    self.fileObserver = FileObserver(fileURL: FileManager.default.temporaryDirectory.appending(component: "jojo.json"))
    
    let userResponseResultPublisher = fileObserver.$data.compactMap{$0}.map { data in
      var urlRequest = URLRequest(url: URL(string: "http://localhost:8080/users")!)
      urlRequest.httpMethod = "POST"
      urlRequest.httpBody = data
      urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")  // the request is JSON
      urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")        // the expected
      return urlRequest
    }.map (
      URLSession.shared.dataTaskPublisher(for:)
    ).switchToLatest().map(\.data)
      .decode(type: UserResponse.self, decoder: JSONDecoder())
    .map(Result.success).catch{ error in
      Just(Result.failure(error))
    }.share()
    
    let failurePublisher = userResponseResultPublisher.compactMap{
      switch $0 {
      case .failure(let error):
        return error
      default:
        return nil
      }
    }
    
    let successPublisher = userResponseResultPublisher.compactMap{
      switch $0 {
      case .success(let value):
        return value
      default:
        return nil
      }
    }
    
    successPublisher.map(Optional.some).receive(on: DispatchQueue.main).assign(to: &self.$userResponse)
    failurePublisher.map(Optional.some).receive(on: DispatchQueue.main).assign(to: &self.$lastError)
      //.receive(on: DispatchQueue.main)
      
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
