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
    
    @IBOutlet weak var saveRecordingView: UIStackView!
    @IBOutlet weak var cancelRecordingButtton: UIButton!
    @IBOutlet weak var saveRecordingButton: UIButton!
    
    @IBOutlet weak var pauseRecordButton: UIButton!
    @IBOutlet weak var playRecordButtonView: UIStackView!
    @IBOutlet weak var reRecordButton: UIButton!
    @IBOutlet weak var playRecordButton: UIButton!
    
    weak var delegate: RecordVoiceNoteDelegate?
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var elapsedTime: TimeInterval = 0
    private var isPlaying = false
    private var recordingURL: URL?
    var onSave: ((URL?) -> Void)?
    
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
        self.state = .recording
    }
    
    @IBAction func cancelRecordingAction(_ sender: UIButton) {
        self.delegate?.recordVoiceScreenDidDismiss()
    }
    
    @IBAction func saveRecordingAction(_ sender: UIButton) {
        self.delegate?.voiceNoteDidRecord()
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.delegate?.recordVoiceScreenDidDismiss()
    }
    
    @IBAction func pauserecordAction(_ sender: UIButton) {
        self.state = .recorded
    }
    
    @IBAction func reRecordAvtion(_ sender: UIButton) {
        self.state = .recording
    }
    
    @IBAction func playRecordAction(_ sender: UIButton) {
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
            DispatchQueue.main.async {
                completion(granted)
            }
        }
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
}

enum RecordingState {
    case idle        // "Start Recording" button visible
    case recording   // waveform + timer + pause button
    case recorded    // waveform + timer + mic(re-record) + play + Save/Cancel
}


protocol RecordVoiceNoteDelegate: AnyObject {
    func recordVoiceScreenDidDismiss()
    func voiceNoteDidRecord()
}
