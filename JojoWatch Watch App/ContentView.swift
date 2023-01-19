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
  let directoryObserver : DirectoryObserver
  @Published var userResponse: UserResponse?
  @Published var lastError : Error?
  init() {
    self.directoryObserver = DirectoryObserver(directoryPath: FileManager.default.temporaryDirectory.path)
    
    
    let dataPublisher = directoryObserver.directoryEventPublisher().compactMap {_ in
      return try? Data(contentsOf: FileManager.default.temporaryDirectory.appendingPathComponent("com.BrightDigit.Jojo.SignInWithApple"))
    }
    
    let dataResponsePublisher = dataPublisher.compactMap{$0}.map { data -> URLRequest in
      var urlRequest = URLRequest(url: URL(string: "http://localhost:8080/users")!)
      urlRequest.httpMethod = "POST"
      urlRequest.httpBody = data
      urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")  // the request is JSON
      urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")        // the expected
      return urlRequest
    }.map { urlRequest in
      return URLSession.shared.dataTaskPublisher(for: urlRequest)
    }.switchToLatest()
    
//
    let userResponseResultPublisher = dataResponsePublisher
      .map(\.data)
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
  }
  
}

struct ContentView: View {
  //@StateObject var directoryObserver = DirectoryObserver()
  @State var error : Error?
  @StateObject var authenticationObject = AuthenticationObject()
  
  var isReady : Bool {
    self.authenticationObject.userResponse?.accessToken != nil
  }
  
  // xcrun simctl get_app_container booted com.BrightDigit.SimTest.watchkitapp data
  @State var accessToken: String?
    var body: some View {
        VStack {
          
          Button("Sign In With Apple") {
            debugPrint("LoggingIn")
          }.disabled(!isReady)
            .foregroundColor(isReady ? .primary : .red)
        }
        .padding()
        .onAppear{
          do {
            try self.authenticationObject.directoryObserver.startMonitoring(triggerImmediately: true)
          } catch {
            Task{ @MainActor in
              self.error = error
            }
          }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
