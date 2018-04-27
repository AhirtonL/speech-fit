//
//  ViewController.swift
//  Speech Fit
//
//  Created by Victor Shinya on 26/04/18.
//  Copyright © 2018 Victor Shinya. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    // MARK: - Global vars
    
    private let speechRecognizer = SFSpeechRecognizer.init(locale: Locale.init(identifier: "pt-BR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var recognizedText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        speechRecognizer?.delegate = self
        setUpSpeechRecognition()
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
    
    func initUI() {
        microphoneButton.layer.cornerRadius = microphoneButton.layer.frame.height / 2
        microphoneButton.clipsToBounds = true
    }
    
    func setUpSpeechRecognition() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            var isEnable = false
            switch authStatus {
            case .notDetermined:
                print("Speech recognition not yet authorized")
            case .denied:
                print("User denied access to speech recognition")
            case .restricted:
                print("Speech recognition restricted on this device")
            case .authorized:
                isEnable = true
            }
            OperationQueue.main.addOperation {
                self.microphoneButton.isEnabled = isEnable
            }
        }
    }
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("An error has occured")
        }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            if result != nil, let text = result?.bestTranscription.formattedString, let final = result?.isFinal {
                print("Recognized audio: " + text)
                self.recognizedText.text = text
                isFinal = final
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.stop()
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine object could not started")
        }
        print("Audio recording started")
    }
    
    @IBAction func startRecognize(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start recording", for: .normal)
        } else {
            startRecording()
            microphoneButton.setTitle("Stop recording", for: .normal)
        }
    }
    
}

