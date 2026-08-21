//
//  RefreshContentHooks.swift
//  Dodo
//
//  Created by Noah Little on 12/8/2026.
//

import DodoC
import Shook
import CydiaSubstrate

@HookGroup
final class RefreshContentHooks {
    
    /// Refreshes content every second.
    @ClassHook("SBUIPreciseClockTimer", type: SBUIPreciseClockTimer.self)
    final class SBUIPreciseClockTimer_Hook  {
        
        @Hook("_handleTimePassed")
        func _handleTimePassed() {
            orig._handleTimePassed()
            guard PreferenceManager.shared.settings.mediaPlayer.timeMediaPlayerStyle != .mediaPlayer else { return }
            NotificationCenter.default.post(name: .refreshContent, object: nil)
        }
    }
    
    /// Keeps track of screen on/off state, to prevent refreshes when screen is off.
    @ClassHook("SBLockScreenPluginManager", type: NSObject.self)
    final class SBLockScreenPluginManager_Hook {
        
        @Hook("setEnabled:")
        func setEnabled(_ enabled: Bool) {
            orig.setEnabled(enabled)
            LocalState.shared.isScreenOff = !enabled
        }
    }
    
    @ClassHook("SpringBoard", type: SpringBoard.self)
    final class SpringBoard_Hook {
        
        @Hook("applicationDidFinishLaunching:")
        func applicationDidFinishLaunching(_ application: AnyObject) {
            orig.applicationDidFinishLaunching(application)
            
            guard PreferenceManager.shared.settings.mediaPlayer.timeMediaPlayerStyle != .time else {
                return
            }
            
            // If media plays through a respring, we need this code to update the media info when
            // SpringBoard launches so that the play/pause button shows the correct image.
            SBMediaController.sharedInstance().setNowPlayingInfo(0)
        }
    }
    
    @ClassHook("DNDNotificationsService", type: DNDNotificationsService.self)
    final class DNDNotificationsService_Hook {
        
        @Hook("stateService:didReceiveDoNotDisturbStateUpdate:")
        func stateService(_ arg1: AnyObject, didReceiveDoNotDisturbStateUpdate update: DNDStateUpdate) {
            orig.stateService(arg1, didReceiveDoNotDisturbStateUpdate: update)
            DispatchQueue.main.async {
                DNDViewModel.shared.isEnabled = update.state.isActive
            }
        }
    }
    
    @ClassHook("SBRingerControl", type: NSObject.self)
    final class SBRingerControl_Hook {
        
        @Hook("setRingerMuted:")
        func setRingerMuted(_ isMuted: Bool) {
            orig.setRingerMuted(isMuted)
            NotificationCenter.default.post(
                name: .didChangeRinger,
                object: nil,
                userInfo: [
                    "isMuted" : isMuted
                ]
            )
        }
    }
}
