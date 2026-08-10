//
//  MediaControlsView.swift
//
//
//  Created by Noah Little on 23/7/2022.
//

import SwiftUI
import DodoC

struct MediaControlsView: View {
    enum MediaControl: CaseIterable, Identifiable {
        case previous
        case play
        case pause
        case next

        var id: Self { self }

        var imageName: String {
            switch self {
            case .previous: return MediaPlayer.ViewModel.themePath + "previous.png"
            case .play: return MediaPlayer.ViewModel.themePath + "play.png"
            case .pause: return MediaPlayer.ViewModel.themePath + "pause.png"
            case .next: return MediaPlayer.ViewModel.themePath + "next.png"
            }
        }

        var fallbackSystemName: String {
            switch self {
            case .previous: return "backward.fill"
            case .play: return "play.fill"
            case .pause: return "pause.fill"
            case .next: return "forward.fill"
            }
        }

        var size: CGFloat {
            switch self {
            case .play, .pause: return 44.0
            default: return 34.0
            }
        }

        static var isPlayingControls: [Self] {
            allCases.filter { $0 != .play }
        }

        static var isPausedControls: [Self] {
            allCases.filter { $0 != .pause }
        }
    }

    let visibleControls: [MediaControl]
    let onDidTapControl: (MediaControl) -> Void

    var body: some View {
        HStack {
            ForEach(visibleControls) { control in
                if let image = UIImage(contentsOfFile: control.imageName)
                    ?? UIImage(systemName: control.fallbackSystemName) {
                    Button {
                        onDidTapControl(control)
                    } label: {
                        Image(uiImage: image)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: control.size, height: control.size)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel(control.fallbackSystemName)
                }
            }
        }
    }
}
