import SwiftUI
import UIKit

/// Keeps the edge swipe back working on a page that hides the system back button for its own back word. It borrows
/// the navigation controller's pop-gesture delegate only while the page is on screen and hands the original back
/// when it leaves, so the root page underneath never gets a swipe with nothing to pop (QA K1).
struct EdgeSwipeBack: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_: Controller, context _: Context) {}

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        private weak var original: (any UIGestureRecognizerDelegate)?
        private weak var borrowedFrom: UINavigationController?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard let navigation = navigationController, let pop = navigation.interactivePopGestureRecognizer,
                  pop.delegate !== self else { return }
            original = pop.delegate
            borrowedFrom = navigation
            pop.isEnabled = true
            pop.delegate = self
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            handBack()
        }

        deinit {
            MainActor.assumeIsolated { handBack() }
        }

        private func handBack() {
            guard let pop = borrowedFrom?.interactivePopGestureRecognizer, pop.delegate === self else { return }
            pop.delegate = original
            borrowedFrom = nil
        }

        func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
            (borrowedFrom?.viewControllers.count ?? 0) > 1
        }
    }
}
