//
//  ContentVieww.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 11/03/25.
//


import SwiftUI

struct ContentVieww: View {
    
    @Namespace private var namespace
    
    let imageUrls = [
        "https://picsum.photos/id/10/300/300",
        "https://picsum.photos/id/11/300/300",
        "https://picsum.photos/id/12/300/300",
        "https://picsum.photos/id/13/300/300",
        "https://picsum.photos/id/14/300/300",
        "https://picsum.photos/id/15/300/300",
        "https://picsum.photos/id/16/300/300",
        "https://picsum.photos/id/17/300/300",
        "https://picsum.photos/id/18/300/300",
        "https://picsum.photos/id/19/300/300",
        "https://picsum.photos/id/20/300/300",
        "https://picsum.photos/id/21/300/300"
    ]
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(imageUrls.indices, id: \.self) { index in
                        NavigationLink {
                            DetailView(imageUrl: imageUrls[index])
                                .navigationTransition(
                                    .zoom(sourceID: "image-\(index)", in: namespace)
                                )
                        } label: {
                            AsyncImage(url: URL(string: imageUrls[index])) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(.gray.opacity(0.2))
                                    .overlay {
                                        ProgressView()
                                    }
                            }
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .matchedTransitionSource(id: "image-\(index)", in: namespace)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.large)
        }
    }
}

struct DetailView: View {
   let imageUrl: String
   
   var body: some View {
       ScrollView {
           VStack(spacing: 0) {
               AsyncImage(url: URL(string: imageUrl)) { image in
                   image
                       .resizable()
                       .aspectRatio(contentMode: .fill)
               } placeholder: {
                   Rectangle()
                       .fill(.gray.opacity(0.2))
               }
               .frame(height: 400)
               
               VStack(alignment: .leading, spacing: 16) {
                   Text("Lorem ipsum dolor sit amet")
                       .font(.title)
                       .fontWeight(.bold)
                   
                   Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
                       .font(.body)
                       .foregroundStyle(.secondary)
               }
               .padding()
           }
       }.navigationTitle("Gallery")
   }
}

#Preview {
    ContentVieww()
}
