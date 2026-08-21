//
//  LayoutHooks.swift
//  Dodo
//
//  Stabilized notification positioning for iOS 15.
//

import DodoC
import UIKit
import Shook
import CydiaSubstrate

@HookGroup
final class LayoutHooks {
 
    @ClassHook("CSCombinedListViewController", type: CSCombinedListViewController.self)
    final class CSCombinedListViewController_Hook {
        @Property private var dodoController: DDBaseController = .init()
        @Property private var trailingConstraint: NSLayoutConstraint = .init()

        @Hook("viewDidLoad")
        func viewDidLoad() {
            orig.viewDidLoad()
            dodoController.view.translatesAutoresizingMaskIntoConstraints = false
            target.addChild(dodoController)
            target.view.addSubview(dodoController.view)
            dodoController.didMove(toParent: target)

            // Keep a reference because the trailing anchor changes with rotation.
            trailingConstraint = dodoController.view.trailingAnchor.constraint(equalTo: target.view.trailingAnchor)
            NSLayoutConstraint.activate([
                dodoController.view.bottomAnchor.constraint(equalTo: target.view.bottomAnchor),
                dodoController.view.leadingAnchor.constraint(equalTo: target.view.leadingAnchor)
            ])
        }

        @Hook("viewWillAppear:")
        func viewWillAppear(_ animated: Bool) {
            orig.viewWillAppear(animated)
            trailingConstraint.isActive = !LocalState.shared.isLandscape
            target.view.setNeedsLayout()
        }
        
        @Hook("_listViewDefaultContentInsets")
        func _listViewDefaultContentInsets() -> UIEdgeInsets {
            var insets = orig._listViewDefaultContentInsets()
            guard !LocalState.shared.isLandscape else { return insets }
            
            // Preserve the system-provided inset (which can grow while a test
            // notification is presented) and only reserve the additional Dodo area
            // once its frame has been measured.
            let dodoHeight = LocalState.shared.dodoFrame.height
            if dodoHeight.isFinite, dodoHeight > 0 {
                insets.bottom = max(insets.bottom, dodoHeight + 50)
            }
            
            guard PreferenceManager.shared.settings.mediaPlayer.timeMediaPlayerStyle != .mediaPlayer else {
                return insets
            }
            
            // A malformed preference must not create a negative system inset.
            let configuredOffset = PreferenceManager.shared.settings.dimensions.notificationVerticalOffset
            let offset = configuredOffset.isFinite ? max(0, min(configuredOffset, 1000)) : 0
            insets.top = max(0, insets.top - offset)
            return insets
        }
    }
}
