//
//  VoiceMessagePlayer.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 26/7/24.
//

import Foundation
import AVFoundation

final class VoiceMessagePlayer: ObservableObject {
    
    private var player: AVPlayer?
    private var currentURL: URL?
    
    private var playerItem: AVPlayerItem?
    private var playbackState = PlaybackState.stopped
    private var currentTime = CMTime.zero
    private var currentTimeObserver: Any?
    
    deinit {
        tearDown()
    }
    
    // Play Audio
    func playAudio(from url: URL) {
        if let currentURL, currentURL == url {
            // Resume that audio
            resumeAudio()
        } else {
            // Play new audio
            currentURL = url
            let playerItem = AVPlayerItem(url: url)
            self.playerItem = playerItem
            player = AVPlayer(playerItem: playerItem)
            player?.play()
            playbackState = .playing
            
            observeCurrentPlayerTime()
            observeEndOfPlayback()
        }
    }
    
    // Pause Audio
    func pauseAudio() {
        player?.pause()
        playbackState = .pause
    }
    
    // Seek Audio
    func seek(to timeInterval: TimeInterval) {
        guard let player else { return }
        let targetTime = CMTime(seconds: timeInterval, preferredTimescale: 1)
        player.seek(to: targetTime)
    }
    
    
    // MARK: - Private Methods
    
    // Resume after pause or stopped somebody audio
    private func resumeAudio() {
        if playbackState == .stopped || playbackState == .pause {
            player?.play()
            playbackState = .playing
        }
    }
    
    private func observeCurrentPlayerTime() {
        currentTimeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: DispatchQueue.main
        ) { [weak self] time in
            self?.currentTime = time
            print("observeCurrentPlayerTime: \(time)")
        }
    }
    
    // Observable when the audio slide finish
    private func observeEndOfPlayback() {
        NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: player?.currentItem, queue: .main) { [weak self] _ in
            self?.stopAudioPlayer()
            print("observeEndOfPlayback")
        }
    }
    
    private func stopAudioPlayer() {
        player?.pause()
        // Reset the voice audio to 0
        player?.seek(to: .zero)
        playbackState = .stopped
        currentTime = .zero
    }
    
    // Remove All Observer
    private func removeObservers() {
        guard let currentTimeObserver else { return }
        player?.removeTimeObserver(currentTimeObserver)
        self.currentTimeObserver = nil
        print("removeObservers fired")
    }
    
    private func tearDown() {
        removeObservers()
        player = nil
        playerItem = nil
        currentURL = nil
    }
}


extension VoiceMessagePlayer {
    enum PlaybackState {
        case stopped, pause, playing
    }
}
