//
//  DisableSwipeBack.swift
//  Controlio
//
//

import SwiftUI

struct DisableSwipeBack: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        DisableSwipeBackController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private class DisableSwipeBackController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}

/// View modifier for easier application
extension View {
    func disableSwipeBack() -> some View {
        self.background(
            DisableSwipeBack()
                .frame(width: 0, height: 0)
        )
    }
}

