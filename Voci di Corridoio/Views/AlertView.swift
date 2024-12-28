//
//  AlertView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 22/12/24.
//

import SwiftUI

struct AlertView: View {
    private var title: LocalizedStringResource
    private var message: LocalizedStringResource
    private var dismissButtonTitle: LocalizedStringResource
    private var onDismiss: () -> Void
    
    init(title: LocalizedStringResource, message: LocalizedStringResource, dismissButtonTitle: LocalizedStringResource = "DAJE", onDismiss: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.dismissButtonTitle = dismissButtonTitle
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onDismiss()
                }
            VStack(spacing: 20) {
                Text(title)
                    .title()
                
                Text(message)
                    .body()
                    .multilineTextAlignment(.center)
                
                Button(action: onDismiss) {
                    Text(dismissButtonTitle)
                        .textButtonStyle(true)
                }
            }
            .alertStyle()
        }
    }
}

#Preview {
    AlertView(title: "test", message: "corpo corpo sium aooa forza roma daje ", onDismiss: {
        print("test")
    })
}
