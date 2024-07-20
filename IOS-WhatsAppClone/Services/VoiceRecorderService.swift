//
//  VoiceRecorderService.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 20/7/24.
//

import Foundation
import AVFoundation
import Combine

/// Recording Voice Message
/// Storing Message URL
final class VoiceRecorderService {
    
    private var audioRecorder: AVAudioRecorder?
    private(set) var isRecording = false
    private var elaspedTime: TimeInterval = 0
    private var startTime: Date?
    private var timer: AnyCancellable?
    
    /// Start recording
    func startRecording() {
        
        /// Setup AudioSession
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.overrideOutputAudioPort(.speaker)
            try audioSession.setActive(true)
            print("VoiceRecorderService: Successfully to setup AVAudioSession")
        } catch {
            print("VoiceRecorderService: Failed to setup AVAudioSession")
        }
        
        /// Where do wanna store the voice message??? URL
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        /// Extension `toString` in Date+Extensions
        let audioFileName = Date().toString(format: "dd-MM-YY 'at' HH:mm:ss") + ".m4a"
        
        /// Main Audio File URL
        let audioFileURL = documentPath.appendingPathComponent(audioFileName) // deprecate
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        /// Start Record
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            audioRecorder?.record()
            isRecording = true
            startTime = Date()
            
            /// Start timer recording
            startTimer()
            print("VoiceRecorderService: Successfully to setup AVAudioRecorder")

        } catch {
            print("VoiceRecorderService: Failed to setup AVAudioRecorder")
        }
    }
    
    
    /// Stop recording
    /// - Parameter completion: return `Audio URL` & How long with that `Audio Duration`
    func stopRecording(completion: ((_ audioURL: URL?, _ audioDuration: TimeInterval) -> Void)? = nil) {
        guard isRecording else { return }
        
        /// before set default elaspedTime return 0 will assign that time into duration time
        let audioDuration = elaspedTime
        
        audioRecorder?.stop()
        isRecording = false
        timer?.cancel()
        
        /// reset elaspedTime
        elaspedTime = 0
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(false)
            guard let audioURL = audioRecorder?.url else { return }
            completion?(audioURL, audioDuration)
        } catch {
            print("VoiceRecorderService: Failed to teardown AVAudioSession")
        }
    }
    
    /// Destroy
    func tearDown() {
        let fileManager = FileManager.default
        let folder = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderContents = try! fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        /// delete all records in the folder temporary
        deleteRecordings(folderContents)
        print("VoiceRecorderService: was successfully teared down")
    }
    
    /// Remove records
    private func deleteRecordings(_ urls: [URL]) {
        for url in urls {
            deleteRecording(at: url)
        }
    }
    
    /// Remove a record
    private func deleteRecording(at fileURL: URL) {
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("Audio File was deleted at \(fileURL)")
        } catch {
            print("Failed to delete File")
        }
    }
    
    /// Start recording time
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let startTime = self?.startTime else { return }
                self?.elaspedTime = Date().timeIntervalSince(startTime)
                print("VoiceRecorderService elasptime: \(self?.elaspedTime)")
            }
    }
}
