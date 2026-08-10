//
//  DDBaseController.swift
//
//
//  Created by Noah Little on 19/11/2022.
//

import UIKit

final class DDBaseController: UIViewController {
    private let hostingController = LSPresentableHostingController(rootView: Container())
    private var didInstallConstraints = false
    private var trailingConstraint: NSLayoutConstraint?

    override func _canShowWhileLocked() -> Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil
        hostingController.view.backgroundColor = nil
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        installConstraintsIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        installConstraintsIfNeeded()
        trailingConstraint?.isActive = !LocalState.shared.isLandscape
    }

    private func installConstraintsIfNeeded() {
        guard !didInstallConstraints else { return }
        didInstallConstraints = true

        trailingConstraint = hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
        trailingConstraint?.isActive = !LocalState.shared.isLandscape
    }
}
