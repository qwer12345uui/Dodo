//
//  NotificationsLayoutHooks.swift
//  Dodo
//
//  Stabilized for iOS 15 notification presentation.
//

import DodoC
import UIKit
import Shook
import CydiaSubstrate

@HookGroup
final class NotificationsLayoutHooks {
    @ClassHook("NCNotificationStructuredListViewController", type: NCNotificationStructuredListViewController.self)
    final class NCNotificationStructuredListViewController_Hook {
        @Property private var cropFrame: CAGradientLayer = .init()

        @Hook("viewDidLoad")
        func viewDidLoad() {
            orig.viewDidLoad()

            NotificationCenter.default.addObserver(
                target,
                selector: #selector(dodoSetupMask),
                name: .didUpdateHeight,
                object: nil
            )

            cropFrame = CAGradientLayer()
            cropFrame.colors = [UIColor.white.cgColor, UIColor.clear.cgColor]
        }

        @Hook("viewDidAppear:")
        func viewDidAppear(_ animated: Bool) {
            orig.viewDidAppear(animated)
            dodoSetupMask()
        }

        @Hook("viewDidLayoutSubviews")
        func viewDidLayoutSubviews() {
            orig.viewDidLayoutSubviews()
            dodoSetupMask()
        }

        @New("dodoSetupMask")
        @objc private func dodoSetupMask() {
            let bounds = target.view.bounds
            let screenHeight = bounds.height
            let dodoFrame = LocalState.shared.dodoFrame

            // iOS 15 may report an empty notification-list view while a test
            // notification is being presented. Never send invalid unit points to
            // Core Animation and never retain an obsolete crop mask in that state.
            guard !LocalState.shared.isLandscape,
                  screenHeight.isFinite,
                  screenHeight > 1,
                  !dodoFrame.isEmpty,
                  dodoFrame.minY.isFinite else {
                clearDodoMask()
                return
            }

            let androBarHeight = PreferenceManager.shared.settings.dimensions.androBarHeight
            let rawStartY = (dodoFrame.minY - androBarHeight - 50) / screenHeight
            let rawEndY = (dodoFrame.minY - androBarHeight) / screenHeight
            guard rawStartY.isFinite, rawEndY.isFinite else {
                clearDodoMask()
                return
            }

            let startY = min(max(rawStartY, 0), 1)
            let endY = min(max(rawEndY, startY), 1)
            let newStart = CGPoint(x: 0.5, y: startY)
            let newEnd = CGPoint(x: 0.5, y: endY)

            // Assigning layer.mask forces the notification list to lay out again.
            // Do nothing when every mask parameter is already current, breaking
            // the didUpdateHeight -> mask -> layout -> didUpdateHeight feedback loop.
            if target.view.layer.mask === cropFrame,
               cropFrame.frame.equalTo(bounds),
               cropFrame.startPoint.equalTo(newStart),
               cropFrame.endPoint.equalTo(newEnd) {
                return
            }

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            cropFrame.frame = bounds
            cropFrame.startPoint = newStart
            cropFrame.endPoint = newEnd
            target.view.layer.mask = cropFrame
            CATransaction.commit()
        }

        private func clearDodoMask() {
            guard target.view.layer.mask === cropFrame else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            target.view.layer.mask = nil
            CATransaction.commit()
        }
    }
}
