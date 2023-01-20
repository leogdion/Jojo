//
//  ContentView.swift
//  JojoWatch Watch App
//
//  Created by Leo Dion on 1/10/23.
//

import SwiftUI
import JojoModels
import Combine
import os.log

class AuthenticationObject<OutputType : Decodable> : ObservableObject {
  @Published var userResponse: OutputType?
  @Published var lastError : Error?
  
  let directoryObserver : DirectoryObserver
  let sourceFileURL : URL
  let urlSession : URLSession
  let createRequestFromData : (Data) -> URLRequest
  private let logger = Logger()
  
  init(sourceFileURL : URL, urlSession : URLSession = .shared, _ createRequestFromData: @escaping (Data) -> URLRequest ) {
    self.sourceFileURL = sourceFileURL
    self.urlSession = urlSession
    self.createRequestFromData = createRequestFromData
    self.directoryObserver = DirectoryObserver(directoryPath: sourceFileURL.deletingLastPathComponent().path)
    
    
    let dataPublisher = directoryObserver.directoryEventPublisher().compactMap {_ in
      
      return try? Data(contentsOf: self.sourceFileURL)
    }
    
    let dataResponsePublisher = dataPublisher.compactMap{$0}.map { data -> URLRequest in
      self.logger.info("[SimulatorServices] - Authenticating from the watch")
      return self.createRequestFromData(data)
    }.map { urlRequest in
      return self.urlSession.dataTaskPublisher(for: urlRequest)
    }.switchToLatest()
    
//
    let userResponseResultPublisher = dataResponsePublisher
      .map(\.data)
      .decode(type: OutputType.self, decoder: JSONDecoder())
    .map(Result.success).catch{ error in
      self.logger.info("[SimulatorServices] - Authentication failure: \(error.localizedDescription)")
      return Just(Result<OutputType, Error>.failure(error))
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
        self.logger.info("[SimulatorServices] - Authentication Success.")
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
  private let logger = Logger()
  @State var error : Error?
  @StateObject var authenticationObject = AuthenticationObject<UserResponse>(
    sourceFileURL: FileManager.default.temporaryDirectory.appendingPathComponent("com.BrightDigit.Jojo.SignInWithApple"),
    Self.createRequestFromData
  )
  
  var isReady : Bool {
    self.authenticationObject.userResponse?.accessToken != nil
  }
  
  static func createRequestFromData(_ data: Data) -> URLRequest {
          var urlRequest = URLRequest(url: URL(string: "http://localhost:8080/users")!)
          urlRequest.httpMethod = "POST"
          urlRequest.httpBody = data
          urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")  // the request is JSON
          urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")        // the expected
          return urlRequest
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
