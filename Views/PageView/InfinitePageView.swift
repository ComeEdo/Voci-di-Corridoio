//
//  InfinitePageView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 19/04/25.
//

import SwiftUI

struct InfinitePageView<Page: View>: View {
    private let pages: [Page]
    @State private var currentPage = 0
    @State private var pageHeight: CGFloat = .zero
    
    init(pages: [Page]) {
        self.pages = pages
    }

    var body: some View {
        if pages.count == 1, let page = pages.first {
            page
        } else if pages.count > 1 {
            ZStack(alignment: .bottomTrailing) {
                InfinitePageViewController(pages: pages, currentPage: $currentPage, pageHeight: $pageHeight)
                    .frame(height: pageHeight)
                PageControl(numberOfPages: pages.count, currentPage: $currentPage)
                    .frame(width: CGFloat(pages.count * 18))
                    .padding(.trailing)
            }
        }
    }
}
