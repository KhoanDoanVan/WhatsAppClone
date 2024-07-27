//
//  BubbleAudioView.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 5/7/24.
//

import SwiftUI
import AVKit
/// AVFoundation: Offers low-level, detailed control over media operations; suitable for complex, custom media processing, capture, and editing tasks.
/// AVKit: Provides high-level, easy-to-use components for media playback; ideal for quickly integrating standard media playback features into an app.

struct BubbleAudioView: View {
    
    @EnvironmentObject private var voiceMessagePlayer: VoiceMessagePlayer
    
    private let item: MessageItem
    @State private var sliderValue: Double = 0
    @State private var sliderRange: ClosedRange<Double>
    @State private var playbackState: VoiceMessagePlayer.PlaybackState = .stopped
    @State private var playbackTime = "00:00"
    @State private var isDragging: Bool = false
    
    init(item: MessageItem) {
        self.item = item
        let audioDuration = item.audioDuration ?? 20
        self._sliderRange = State(wrappedValue: 0...audioDuration)
    }
    
    private var isCorrectVoiceMessage: Bool {
        return voiceMessagePlayer.currentURL?.absoluteString == item.audioURL
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {
            if item.showGroupPartnerInfo {
                CircularProfileImageView(item.sender?.profileImageUrl, size: .mini)
                    .offset(y: 5)
            }
            
            if item.direction == .sent {
                timeStampTextView()
            }
            
            HStack {
                playButton()
                
                Slider(value: $sliderValue, in: sliderRange) { editing in
                    isDragging = editing // boolean
                    if !editing || isCorrectVoiceMessage {
                        voiceMessagePlayer.seek(to: sliderValue)
                    }
                }
                .tint(.gray)
                
                if playbackState == .stopped {
                    // if stopped, us will use the duration time
                    Text(item.audioDurationInString)
                        .foregroundStyle(.gray)
                } else {
                    // if playing, us will the playbacktime by listen observe
                    Text(playbackTime)
                        .foregroundStyle(.gray)
                }
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(5)
            .background(item.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .applyTail(item.direction)
            
            if item.direction == .received {
                timeStampTextView()
            }
        }
        .shadow(color: Color(.systemGray3).opacity(0.1), radius: 5, x: 0, y: 20)
        .frame(maxWidth: .infinity, alignment: item.alignment)
        .padding(.leading, item.leadingPadding)
        .padding(.trailing, item.trailingPadding)
        .onReceive(voiceMessagePlayer.$playbackState) { state in // observer state of message audio player
            observePlaybackState(state)
        }
        .onReceive(voiceMessagePlayer.$currentTime) { currentTime in // observer time current playing
            guard voiceMessagePlayer.currentURL?.absoluteString == item.audioURL else { return } // avoid display range of slide other at the same time
            listenTime(to: currentTime)
        }
    }
    
    private func playButton() -> some View {
        Button {
            handlePlayAudioMessage()
        } label: {
            Image(systemName: playbackState.icon)
                .padding(10)
                .background(item.direction == .received ? .green : .white)
                .clipShape(Circle())
                .foregroundStyle(item.direction == .received ? .white : .black)
        }
    }
    
    private func timeStampTextView() -> some View {
        Text(item.timeStamp.formatToTime)
            .font(.footnote)
            .foregroundStyle(.gray)
    }
}

extension BubbleAudioView {
    private func handlePlayAudioMessage() {
        if playbackState == .pause || playbackState == .stopped {
            guard let audioURLString = item.audioURL,
                  let voiceMessageUrl = URL(string: audioURLString)
            else { return }
            
            voiceMessagePlayer.playAudio(from: voiceMessageUrl)
        } else {
            voiceMessagePlayer.pauseAudio()
        }
    }
    
    private func observePlaybackState(_ state: VoiceMessagePlayer.PlaybackState) {
        switch state {
        case .stopped:
            playbackState = .stopped
            sliderValue = 0 // when the end of the audio, its will reset the slide range to 0
        case .pause, .playing:
            if isCorrectVoiceMessage {
                playbackState = state
            }
        }
    }
    
    private func listenTime(to currentTime: CMTime) {
        guard !isDragging else { return }
        playbackTime = currentTime.seconds.formatElaspedTime
        sliderValue = currentTime.seconds
    }
}

#Preview {
    ScrollView {
        BubbleAudioView(item: .sentPlaceholder)
            .padding()
        BubbleAudioView(item: .receivedPlaceholder)
            .padding()
    }
    .frame(maxWidth: .infinity)
    .background(Color.gray.opacity(0.4))
}
