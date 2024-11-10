//
//  Voci_di_CorridoioApp.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 06/11/24.
//

import SwiftUI

@main
struct Voci_di_CorridoioApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            if true {
                LogIn()
            } else {
                ContentView()
            }
        }
    }
}
