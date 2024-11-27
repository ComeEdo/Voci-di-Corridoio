//
//  LogIn.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 08/11/24.
//

import SwiftUI

struct LogIn: View {
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorGradient()
                VStack {
                    Text("Welcome")
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
                                .foregroundColor(Color.white)
                        }
                    NavigationLink(destination: RegisterView()) {
                        Text("Registarti")
                            .fontWeight(.bold)
                            .frame(width: 200)
                            .padding(.vertical)
                            .background(.tint, in: RoundedRectangle(cornerRadius: 20))
                            .foregroundColor(Color.white)
                    }
                }
            }
        }.foregroundStyle(Color.accentColor)
    }
}

#Preview {
    LogIn()
}
