//
//  PageView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 16/05/25.
//

import SwiftUI

struct PageView<Page: View>: View {
    private let pages: [Page]
    @Binding private var currentPage: Int
    @State private var pageHeight: CGFloat = .zero
    
    init(pages: [Page], currentPage: Binding<Int>) {
        self.pages = pages
        self._currentPage = currentPage
    }
    
    var body: some View {
        if pages.count == 1, let page = pages.first {
            page
        } else if pages.count > 1 {
            PageViewController(pages: pages, currentPage: $currentPage, pageHeight: $pageHeight)/*frame(height: pageHeight)*/
        }
    }
}
