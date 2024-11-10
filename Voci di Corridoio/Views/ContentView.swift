//
//  ContentView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 06/11/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("This is the First View")
                NavigationLink("Go to Second View", destination: SwiftUIView())
            }
            .navigationTitle("Home")
        }
        Button("Outlined Button") {}
            .foregroundColor(.blue)
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue, lineWidth: 2)
            )
            .padding()
    }
    
}

#Preview {
    ContentView()
}
