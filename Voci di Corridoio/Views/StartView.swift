//
//  StartView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 08/11/24.
//

import SwiftUI

struct StartView: View {
    @FocusState private var focusedButton: ButtonType? // Focus state for buttons
        
    enum ButtonType {
        case accedi, creaAccount
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorGradient()
                VStack {
                    Text("Benvenuto")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .padding()
                    Spacer()
                }
                VStack {
                    NavigationLink(destination: SignInView()) {
                        Text("Accedi")
                            .fontWeight(.bold)
                            .frame(width: 200)
                            .padding(.vertical)
                            .background(.tint, in: RoundedRectangle(cornerRadius: 20))
                            .foregroundStyle(Color.white)
                    }
                    .focused($focusedButton, equals: .accedi) // Bind to focus state
                                        .disabled(focusedButton != nil && focusedButton != .accedi) // Disable if another button is focused
                                        .onTapGesture {
                                            focusedButton = .accedi // Set focus to this button
                                        }
                    NavigationLink(destination: CreateAccountView()) {
                        Text("Crea account")
                            .fontWeight(.bold)
                            .frame(width: 200)
                            .padding(.vertical)
                            .background(.tint, in: RoundedRectangle(cornerRadius: 20))
                            .foregroundStyle(Color.white)
                    }
                    .focused($focusedButton, equals: .creaAccount) // Bind to focus state
                                        .disabled(focusedButton != nil && focusedButton != .creaAccount) // Disable if another button is focused
                                        .onTapGesture {
                                            focusedButton = .creaAccount // Set focus to this button
                                        }
                }
            }
            .navigationTitle("")
        }
        .foregroundStyle(Color.accentColor)
    }
}

#Preview {
    StartView()
}
