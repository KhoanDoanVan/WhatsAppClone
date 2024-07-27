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
    @Published private(set) var isRecording = false /// default (set, get) is private
    @Published private(set) var elaspedTime: TimeInterval = 0
    private var startTime: Date?
    private var timer: AnyCancellable?
    
    // MARK: - Deinit
    deinit {
        tearDown()
        print("VoiceRecorderService has been deinited")
    }
    
    
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
        
        /// Haptic
        generateHapticFeedback()
        
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
        
        /// Haptic
        generateHapticFeedback()
        
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
        if isRecording {
            stopRecording()
        }
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
    func deleteRecording(at fileURL: URL) {
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
                print("VoiceRecorderService elasptime: \(String(describing: self?.elaspedTime))")
            }
    }
    
    /// Tegration haptic sound and vibration when just click the record
    private func generateHapticFeedback() {
        let systemSoundID: SystemSoundID = 1118
        AudioServicesPlaySystemSound(systemSoundID)
        /// Vibration
        Haptic.impact(.medium)
    }
}
