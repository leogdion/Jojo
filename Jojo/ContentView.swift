//
//  ContentView.swift
//  Jojo
//
//  Created by Leo Dion on 1/9/23.
//

import SwiftUI
import AuthenticationServices
import JojoModels

struct ContentView: View {
  
  @State var accessToken : String?
    var body: some View {
      if let accessToken {
        Text(accessToken)
      } else {
        VStack {
          SignInWithAppleButton { request in
            request.requestedScopes = [.email, .fullName]
          } onCompletion: { result in
            let credential : ASAuthorizationAppleIDCredential
            
            switch result {
            case .failure(let error):
              debugPrint(error)
              return
            case .success(let auth):
              guard let creds = auth.credential as? ASAuthorizationAppleIDCredential else {
                return
              }
              credential = creds
              
            }
            let appleIdentityToken = credential.identityToken.flatMap { String(data: $0, encoding: .utf8) }
            
            guard let appleIdentityToken else {
              return
            }
            
            let body = SIWARequestBody(email: credential.email, firstName: credential.fullName?.givenName, lastName: credential.fullName?.familyName, appleIdentityToken: appleIdentityToken)
            Task {
              var urlRequest = URLRequest(url: URL(string: "http://localhost:8080/users")!)
              urlRequest.httpMethod = "POST"
              urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")  // the request is JSON
              urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")        // the expected response is also JSON

              urlRequest.httpBody = try! JSONEncoder().encode(body)
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
              }
            }
          }
          
        }
        .padding()
      }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
