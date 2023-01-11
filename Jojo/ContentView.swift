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
    var body: some View {
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
              var urlRequest = URLRequest(url: URL(string: "http://localhost:8080/sim")!)
              urlRequest.httpMethod = "POST"
              urlRequest.httpBody = try! JSONEncoder().encode(body)
              let response : URLResponse
              do {
                (_, response) = try await URLSession.shared.data(for: urlRequest)
              } catch {
                debugPrint(error)
                return
              }
              
              dump(response)
            }
          }

        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
