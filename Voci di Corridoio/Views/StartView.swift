//
//  StartView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 08/11/24.
//

import SwiftUI

struct StartView: View {
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
                    NavigationLink(destination: CreateAccountView()) {
                        Text("Crea account")
                            .fontWeight(.bold)
                            .frame(width: 200)
                            .padding(.vertical)
                            .background(.tint, in: RoundedRectangle(cornerRadius: 20))
                            .foregroundStyle(Color.white)
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
