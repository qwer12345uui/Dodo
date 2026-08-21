//
//  NotificationBridge.swift
//  
//
//  Created by Noah Little on 28/4/2023.
//

import Foundation
import DodoC

// TODO: - FIXME
final class NotificationBridge {
    enum DarwinNotification: String {
        case ringVibrate = "com.apple.springboard.ring-vibrate.changed"
        case silentVibrate = "com.apple.springboard.silent-vibrate.changed"

        var translatedName: Notification.Name {
            switch self {
            case .ringVibrate:
                return .didChangeRingVibrate
            case .silentVibrate:
                return .didChangeSilentVibrate
            }
        }
    }
        
    init() { }
}

private extension NotificationBridge {
    
    func post(_ notification: DarwinNotification) {
        NotificationCenter.default.post(name: notification.translatedName, object: nil)
    }
}
