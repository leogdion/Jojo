//
//  ContentView.swift
//  JojoWatch Watch App
//
//  Created by Leo Dion on 1/10/23.
//

import SwiftUI

struct ContentView: View {
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
