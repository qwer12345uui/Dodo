//
//  NotificationsLayoutHooks.swift
//  Dodo
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
                selector: #selector(dodoScheduleMask),
                name: .didUpdateHeight,
                object: nil
            )
            cropFrame = CAGradientLayer()
            cropFrame.colors = [UIColor.white.cgColor, UIColor.clear.cgColor]
        }

        @Hook("viewDidAppear:")
        func viewDidAppear(_ animated: Bool) {
            orig.viewDidAppear(animated)
            dodoScheduleMask()
        }

        @Hook("viewDidLayoutSubviews")
        func viewDidLayoutSubviews() {
            orig.viewDidLayoutSubviews()
            dodoScheduleMask()
        }

        @Hook("viewWillDisappear:")
        func viewWillDisappear(_ animated: Bool) {
            orig.viewWillDisappear(animated)
            NSObject.cancelPreviousPerformRequests(
                withTarget: target,
                selector: #selector(dodoSetupMask),
                object: nil
            )
        }

        @New("dodoScheduleMask")
        @objc private func dodoScheduleMask() {
            guard !LocalState.shared.isLandscape else {
                target.view.layer.mask = nil
                return
            }

            // A push insertion can trigger several height and layout callbacks in one
            // transaction. Defer and coalesce mask work to avoid recursive list layout.
            NSObject.cancelPreviousPerformRequests(
                withTarget: target,
                selector: #selector(dodoSetupMask),
                object: nil
            )
            target.perform(#selector(dodoSetupMask), with: nil, afterDelay: 0)
        }

        @New("dodoSetupMask")
        @objc private func dodoSetupMask() {
            guard !LocalState.shared.isLandscape, target.view.window != nil else {
                target.view.layer.mask = nil
                return
            }

            let bounds = target.view.bounds.integral
            let screenHeight = bounds.height
            guard screenHeight > 0 else { return }

            let androBarHeight = PreferenceManager.shared.settings.dimensions.androBarHeight
            let rawStartY = (LocalState.shared.dodoFrame.minY - androBarHeight - 50) / screenHeight
            let rawEndY = (LocalState.shared.dodoFrame.minY - androBarHeight) / screenHeight
            let startY = min(max(rawStartY, 0), 1)
            let endY = min(max(rawEndY, startY), 1)
            let newStart = CGPoint(x: 0.5, y: startY)
            let newEnd = CGPoint(x: 0.5, y: endY)

            let needsFrameUpdate = !cropFrame.frame.equalTo(bounds)
            let needsMaskAssignment = target.view.layer.mask !== cropFrame
            let needsGradientUpdate = !cropFrame.startPoint.equalTo(newStart)
                || !cropFrame.endPoint.equalTo(newEnd)
            guard needsFrameUpdate || needsMaskAssignment || needsGradientUpdate else { return }

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if needsFrameUpdate { cropFrame.frame = bounds }
            if needsGradientUpdate {
                cropFrame.startPoint = newStart
                cropFrame.endPoint = newEnd
            }
            if needsMaskAssignment { target.view.layer.mask = cropFrame }
            CATransaction.commit()
        }
    }
}
