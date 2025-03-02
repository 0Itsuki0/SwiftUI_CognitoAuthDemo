//
//  CognitoDemoApp.swift
//  CognitoDemo
//
//  Created by Itsuki on 2025/02/26.
//

import SwiftUI

@main
struct CognitoDemoApp: App {
    @State var cognitoManager = CognitoManager()

    var body: some Scene {
        WindowGroup {
            NavigationStack() {
                ContentView()
                    .environment(cognitoManager)
            }
        }
    }
}
