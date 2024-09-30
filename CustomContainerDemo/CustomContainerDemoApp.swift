//
//  CustomContainerDemoApp.swift
//  CustomContainerDemo
//
//  Created by Itsuki on 2024/09/26.
//

import SwiftUI

@main
struct CustomContainerDemoApp: App {
    let items = [0, 1, 2, 3, 4, 5, 6, 7]
    var body: some Scene {
        WindowGroup {
            V10ContentView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(.gray.opacity(0.2))

        }
    }
}
