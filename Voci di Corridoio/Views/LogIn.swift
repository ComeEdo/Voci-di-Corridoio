//
//  LogIn.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 08/11/24.
//

import SwiftUI

struct LogIn: View {
    var body: some View {
        VStack() {
            NavigationStack {
                ZStack {
                    VStack {
                        Text("Welcome")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .padding()
                        Spacer()
                    }
                    VStack {
                        NavigationLink("Accedi", destination: SignInView())
                            .fontWeight(.bold)
                            .frame(width: 200)
                            .padding(.vertical)
                            .background(.tint, in: RoundedRectangle(cornerRadius: 20))
                            .foregroundColor(Color.white)
                        NavigationLink("Registarti", destination: RegisterView())
                            .fontWeight(.bold)
                            .frame(width: 200)
                            .padding(.vertical)
                            .background(.tint, in: RoundedRectangle(cornerRadius: 20))
                            .foregroundColor(Color.white)
                    }
                }
            }
        }
    }
}

#Preview {
    LogIn()
}
