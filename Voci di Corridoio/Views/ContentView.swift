//
//  ContentView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 06/11/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    var body: some View {
        Button("Register") {
            Text("roma la mejo").cornerRadius(10)
        }
        Button("dio") {
            Text("Sign In")
        }
    }
    
}
    

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
