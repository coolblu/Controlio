//
//  DisableSwipeBack.swift
//  Controlio
//
//  Created by Avis Luong on 12/7/25.
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

extension View {
    func disableSwipeBack() -> some View {
        self.background(
            DisableSwipeBack()
                .frame(width: 0, height: 0)
        )
    }
}

