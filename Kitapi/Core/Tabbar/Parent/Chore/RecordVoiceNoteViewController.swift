//
//  RecordVoiceNoteViewController.swift
//  Kitapi
//
//  Created by Suneel on 10/06/26.
// 19-06

import UIKit
import AVFoundation

class RecordVoiceNoteViewController: UIViewController {
    
    @IBOutlet weak var appBGView: UIView!
    
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var startRecordingView: UIStackView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var startRecordingButton: UIButton!
    
    @IBOutlet weak var timerView: UIView!
    @IBOutlet weak var timeMarkerView: UIView!
    @IBOutlet weak var timerLabel: UILabel!
    
    @IBOutlet weak var audioWaveImageView: UIImageView!
    @IBOutlet weak var saveRecordingView: UIStackView!
    @IBOutlet weak var cancelRecordingButtton: UIButton!
    @IBOutlet weak var saveRecordingButton: UIButton!
    
    @IBOutlet weak var pauseRecordButton: UIButton!
    @IBOutlet weak var playRecordButtonView: UIStackView!
    @IBOutlet weak var reRecordButton: UIButton!
    @IBOutlet weak var playRecordButton: UIButton!
    
    weak var delegate: RecordVoiceNoteDelegate?
    
    // MARK: Private — audio
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var elapsedTime: TimeInterval = 0
    private var isPlaying = false
    private var recordingURL: URL?
    
    
    static var sbIdentifier: String {
        return String(describing: RecordVoiceNoteViewController.self)
    }
    
    private var state: RecordingState = .idle {
        didSet {
            self.updateUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setRecordVoiceScreenUI()
    }
    
    @IBAction func StartRecordingAction(_ sender: UIButton) {
        self.startRecording()
    }
    
    //Audio has been recorded. Do u want to save or cancel
    @IBAction func cancelRecordingAction(_ sender: UIButton) {
        self.cancelAndDismiss()
    }
    
    @IBAction func saveRecordingAction(_ sender: UIButton) {
        guard let url = self.recordingURL else { return }
        self.delegate?.voiceNoteDidRecord(audioURL: url)
    }
    
    // Idle state — user hasn't started yet
    @IBAction func cancelAction(_ sender: Any) {
        self.cancelAndDismiss()
    }
    
    // Recording state — mic is live
    @IBAction func pauserecordAction(_ sender: UIButton) {
        self.pauseRecording()
    }
    
    // Recorded state — take exists, user reviews
    @IBAction func reRecordAvtion(_ sender: UIButton) {
        self.reRecord()
    }
    
    @IBAction func playRecordAction(_ sender: UIButton) {
        self.togglePlayback()
    }
    
    private func configureSessionAndRequestPermission(completion: @escaping (Bool) -> Void) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
            completion(false)
            return
        }
        
        session.requestRecordPermission { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    }
    
    private func startRecording() {
        self.configureSessionAndRequestPermission { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                self.showMicPermissionDeniedAlert()
                return
            }
            self.beginRecordingSession()
        }
    }
    
    private func beginRecordingSession() {
        // Fresh temp file every time — nothing is written to Documents/App Support.
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        self.recordingURL = url
        
        let settings: [String: Any] = [
            AVFormatIDKey:            kAudioFormatMPEG4AAC,
            AVSampleRateKey:          44100,
            AVNumberOfChannelsKey:    1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            self.audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            self.audioRecorder?.delegate = self
            self.audioRecorder?.record()
            self.elapsedTime = 0
            self.updateTimerLabel()
            self.state = .recording
            self.startWaveformAnimation()
            self.startTimer()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    // MARK: Pause  (recording → recorded)
    
    private func pauseRecording() {
        self.elapsedTime = audioRecorder?.currentTime ?? elapsedTime
        self.audioRecorder?.stop()
        self.stopWaveformAnimation()
        self.stopTimer()
        self.state = .recorded
    }
    
    // MARK: Re-record  (recorded → recording, previous take discarded)
    
    private func reRecord() {
        self.stopPlayback()
        self.deleteCurrentRecordingFile()
        self.startRecording()
    }
    
    // MARK: Playback
    
    private func togglePlayback() {
        isPlaying ? stopPlayback() : playRecording()
    }
    
    private func playRecording() {
        guard let url = recordingURL else { return }
        do {
            // Switch session category so audio routes to the speaker correctly.
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            self.audioPlayer = try AVAudioPlayer(contentsOf: url)
            self.audioPlayer?.delegate = self
            self.audioPlayer?.play()
            self.isPlaying = true
            self.startWaveformAnimation()
            self.refreshPlayButtonIcon()
        } catch {
            print("Failed to play recording: \(error)")
        }
    }
    
    private func stopPlayback() {
        self.audioPlayer?.stop()
        self.audioPlayer = nil
        self.isPlaying   = false
        self.stopWaveformAnimation()
        self.refreshPlayButtonIcon()
    }
    
    // MARK: Cancel
    
    private func cancelAndDismiss() {
        self.stopTimer()
        self.stopPlayback()
        self.audioRecorder?.stop()
        self.deleteCurrentRecordingFile()
        self.elapsedTime = 0
        self.state = .idle
        self.delegate?.recordVoiceScreenDidDismiss()
    }
    
    // MARK: Helpers
    
    private func deleteCurrentRecordingFile() {
        if let url = self.recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        self.recordingURL = nil
    }
    
    private func startTimer() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedTime += 1
            self.updateTimerLabel()
        }
    }
    
    private func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    private func showMicPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Microphone Access Required",
            message: "Please enable microphone access in Settings to record a voice note.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
    }
    
    deinit {
        self.timer?.invalidate()
        self.timer = nil
    }
}

// MARK: - AVAudioRecorderDelegate
 
extension RecordVoiceNoteViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        // No-op: pause/cancel drive all state transitions explicitly.
        // If the system interrupts the recording (e.g. phone call), move to recorded
        // so the user can still save what was captured.
        if !flag {
            DispatchQueue.main.async {
                self.stopTimer()
                self.stopWaveformAnimation()
                self.state = .recorded
            }
        }
    }
}
 
// MARK: - AVAudioPlayerDelegate
 
extension RecordVoiceNoteViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.isPlaying = false
        self.stopWaveformAnimation()
        self.refreshPlayButtonIcon()
    }
}
extension RecordVoiceNoteViewController {
    
    private func setRecordVoiceScreenUI() {
        self.state = .idle
        self.appBGView.setGradientBackground()
        
        self.headerLabel.text = APPConstants.recordVoiceTitle
        self.headerLabel.textAlignment = .center
        self.headerLabel.font = UIFont(name: Fonts.urbanistBold, size: 22)
        self.headerLabel.textColor = .headerLabekColor
        self.headerLabel.numberOfLines = 1
        
        self.timerLabel.text = "00:00"
        self.timerLabel.textAlignment = .center
        self.timerLabel.font = UIFont(name: Fonts.urbanistExtraBold, size: 15)
        self.timerLabel.textColor = .buttonBackgroundColor
        self.timerLabel.numberOfLines = 1
        
        self.timeMarkerView.layer.cornerRadius = 5
        self.timeMarkerView.backgroundColor = .pinkPrimaryColor
        
        self.pauseRecordButton.layer.cornerRadius = 20
        self.pauseRecordButton.backgroundColor = .buttonBackgroundColor
        
        self.reRecordButton.layer.cornerRadius = 20
        self.reRecordButton.backgroundColor = .buttonBackgroundColor
        
        self.playRecordButton.layer.cornerRadius = 20
        self.playRecordButton.backgroundColor = .buttonBackgroundColor
        
        self.startRecordingButton.setTitle(APPConstants.startRecordingTitle, for: .normal)
        self.startRecordingButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.startRecordingButton.setTitleColor(.white, for: .normal)
        self.startRecordingButton.backgroundColor = .pinkPrimaryColor
        self.startRecordingButton.layer.cornerRadius = 25
        
        self.cancelButton.setTitle(APPConstants.cancelTitle, for: .normal)
        self.cancelButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.cancelButton.setTitleColor(.labelPlaceholderColor, for: .normal)
        self.cancelButton.backgroundColor = .white
        self.cancelButton.layer.cornerRadius = 25
        self.cancelButton.layer.borderColor = UIColor.pinkPrimaryColor.cgColor
        self.cancelButton.layer.borderWidth = 1
        
        self.saveRecordingButton.setTitle(APPConstants.saveTitle, for: .normal)
        self.saveRecordingButton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.saveRecordingButton.setTitleColor(.white, for: .normal)
        self.saveRecordingButton.backgroundColor = .pinkPrimaryColor
        self.saveRecordingButton.layer.cornerRadius = 25
        
        self.cancelRecordingButtton.setTitle(APPConstants.cancelTitle, for: .normal)
        self.cancelRecordingButtton.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        self.cancelRecordingButtton.setTitleColor(.labelPlaceholderColor, for: .normal)
        self.cancelRecordingButtton.backgroundColor = .white
        self.cancelRecordingButtton.layer.cornerRadius = 25
        self.cancelRecordingButtton.layer.borderColor = UIColor.pinkPrimaryColor.cgColor
        self.cancelRecordingButtton.layer.borderWidth = 1
    }
    
    private func updateUI() {
        switch state {
        case .idle:
            // self.waveformView.isHidden = true
            self.timerView.isHidden = true
            self.pauseRecordButton.isHidden = true
            self.playRecordButtonView.isHidden = true
            self.saveRecordingView.isHidden = true
            self.startRecordingView.isHidden = false
            
        case .recording:
            // self.waveformView.isHidden = true
            self.timerView.isHidden = false
            self.pauseRecordButton.isHidden = false
            self.playRecordButtonView.isHidden = true
            self.saveRecordingView.isHidden = true
            self.startRecordingView.isHidden = true
            
        case .recorded:
            // self.waveformView.isHidden = true
            self.timerView.isHidden = false
            self.pauseRecordButton.isHidden = true
            self.playRecordButtonView.isHidden = false
            self.saveRecordingView.isHidden = false
            self.startRecordingView.isHidden = true
        }
    }
    
    private func updateTimerLabel() {
        let total   = Int(elapsedTime)
        let minutes = total / 60
        let seconds = total % 60
        self.timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Swaps the play button icon between play and stop without UIButton.Configuration
    
    private func refreshPlayButtonIcon() {
        let symbolName = isPlaying ? "stop.fill" : "play.fill"
        let config     = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let image      = UIImage(systemName: symbolName, withConfiguration: config)?
            .withRenderingMode(.alwaysTemplate)
        self.playRecordButton.setImage(image, for: .normal)
        self.playRecordButton.tintColor = .white
    }
    
    private func startWaveformAnimation() {
        let animation = CABasicAnimation(keyPath: "transform.scale.x")
        animation.fromValue = 1.0
        animation.toValue = 1.08
        animation.duration = 0.4
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        self.audioWaveImageView.layer.add(animation, forKey: "waveform-1")
    }

    private func stopWaveformAnimation() {
        self.audioWaveImageView.layer.removeAnimation(forKey: "waveform-1")
    }
}

enum RecordingState {
    case idle        // "Start Recording" button visible
    case recording   // waveform + timer + pause button
    case recorded    // waveform + timer + mic(re-record) + play + Save/Cancel
}


protocol RecordVoiceNoteDelegate: AnyObject {
    func recordVoiceScreenDidDismiss()
    func voiceNoteDidRecord(audioURL: URL)
}
