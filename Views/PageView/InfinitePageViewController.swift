//
//  InfinitePageViewController.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 19/04/25.
//

import SwiftUI

struct InfinitePageViewController<Page: View>: UIViewControllerRepresentable {
    var pages: [Page]
    @Binding var currentPage: Int
    @Binding var pageHeight: CGFloat

    @State private var lastPage: Int = 0

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [UIPageViewController.OptionsKey.interPageSpacing: 8]
        )
        pvc.dataSource = context.coordinator
        pvc.delegate = context.coordinator

        // start on the first page
        if let first = context.coordinator.controllers.first {
            pvc.setViewControllers([first], direction: .forward, animated: false)
        }

        return pvc
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        // Figure out animation direction
        let direction: UIPageViewController.NavigationDirection = currentPage >= context.coordinator.parent.lastPage ? .forward : .reverse

        // Grab the target VC
        let vc = context.coordinator.controllers[currentPage]
        uiViewController.setViewControllers([vc], direction: direction, animated: true)

        // Measure its height and push it back to SwiftUI
        let targetSize = vc.view.systemLayoutSizeFitting(CGSize(width: uiViewController.view.bounds.width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        
        DispatchQueue.main.async {
            context.coordinator.parent.lastPage = currentPage
            self.pageHeight = targetSize.height
        }
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: InfinitePageViewController
        var controllers: [UIViewController]
        
        init(_ infinitePageViewController: InfinitePageViewController) {
            parent = infinitePageViewController
            controllers = parent.pages.map { UIHostingController(rootView: $0) }
        }

        // MARK: - Data Source
        func pageViewController(_ pvc: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let idx = controllers.firstIndex(of: viewController) else { return nil }
            let prev = (idx - 1 + controllers.count) % controllers.count
            return controllers[prev]
        }
        func pageViewController(_ pvc: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let idx = controllers.firstIndex(of: viewController) else { return nil }
            let next = (idx + 1) % controllers.count
            return controllers[next]
        }

        // MARK: - Delegate
        func pageViewController(_ pvc: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            guard completed && finished, let visible = pvc.viewControllers?.first, let index = controllers.firstIndex(of: visible) else { return }
            parent.currentPage = index
        }
    }
}
