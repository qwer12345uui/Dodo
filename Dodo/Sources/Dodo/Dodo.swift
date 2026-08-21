//
//  Dodo.swift
//  Dodo
//
//  Created by Noah Little on 8/8/2026.
//

import DodoC
import UIKit
import Shook
import CydiaSubstrate
import GSCore

// MARK: - Tweak

@objc(Tweak)
@objcMembers
public class Tweak: NSObject {

    public static func setup() {
        guard readPrefs(), PreferenceManager.shared.settings.isEnabled else { return }
        HideLockScreenComponentsHooks.activate()
        LayoutHooks.activate()
        NotificationsLayoutHooks.activate()
        RefreshContentHooks.activate()
    }

    private static func prefsDict() -> [String : Any]? {
        let path = "/var/mobile/Library/Preferences/com.ginsu.dodo.plist"
        let plistURL = URL(fileURLWithPath: path)
        return plistURL.plistDict()
    }

    private static func readPrefs() -> Bool {
        if let dict = prefsDict() {
            PreferenceManager.shared.loadSettings(withDictionary: dict)
            return true
        } else {
            return false
        }
    }
}
