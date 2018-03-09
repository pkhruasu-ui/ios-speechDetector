//
//  ViewController.swift
//  SpeechDetector
//
//  Created by Khruasuwan, Prajak(AWF) on 3/5/18.
//  Copyright © 2018 Khruasuwan, Prajak(AWF). All rights reserved.
//

import UIKit
import Speech
import AVFoundation

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    //MARK: Properties
    
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var detectedTextLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    
    let synth = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")
    var timerToStopSpeech = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.requestSpeechAuthorization()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK ACTION
    @IBAction func startButtonTapped(_ sender: Any) {
        
        if audioEngine.isRunning {
            // cleanup
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            request.endAudio()
        } else {
            // start
            recordAndRecognizeSpeech()
        }
    }
    
    func recordAndRecognizeSpeech(){
        // prepare the channel
        let node = audioEngine.inputNode    //get one node
        let recordingFormat = node.outputFormat(forBus: 0)  //get format of that bus(channel) from that node
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat){   // configures the node and sets up the request instance with the proper buffer on the proper bus
            buffer, _ in self.request.append(buffer)
        }
        // prepare the engine
        audioEngine.prepare()
        // start
        do {
            if !audioEngine.isRunning {
                try audioEngine.start()
                timerToStopSpeech = startSPeechDelayTimerToStop()
                startButton.setTitle("Stop", for: .normal)
            }
        } catch {
            return print(error)
        }
        
        guard let myRecognizer = SFSpeechRecognizer() else {
            // A recognizer is not supported for the current locale
            return
        }
        
        if !myRecognizer.isAvailable {
            // A recognizer is not available right now
            return
        }
        // process result
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                self.detectedTextLabel.text = bestString
                // say what has been return
                // audio will "stutter" because data is streaming in. In real app, we would response when all is done
                self.textToSpeech(text: bestString)
                
                // change color base on the last text output
                var lastString: String = ""
                for segment in result.bestTranscription.segments {
                    let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                    lastString = String(bestString[indexTo...])
                }
                
                self.checkForColorsSaid(resultString: lastString)
                
                // extend the timer
                self.timerToStopSpeech = self.startSPeechDelayTimerToStop()
                
                
            } else if let error = error {
//                print(error)  // not an actual error. this happen when there is no sound coming in
            }})
    }
    
    func checkForColorsSaid(resultString: String) {
        switch resultString {
            case "red":
                colorView.backgroundColor = UIColor.red;
            case "green":
                colorView.backgroundColor = UIColor.green;
            case "blue":
                colorView.backgroundColor = UIColor.blue;
        default: break
        }
    }

    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                    case .authorized:
                        self.startButton.isEnabled = true
                case .denied:
                        self.startButton.isEnabled = false
                        self.detectedTextLabel.text = "User denied access to speech recognition"
                case .restricted:
                        self.startButton.isEnabled = false
                        self.detectedTextLabel.text = "Speech recognition is restricted on this device"
                case .notDetermined:
                        self.startButton.isEnabled = false
                        self.detectedTextLabel.text = "Speech recognition not yet authorized"
                }
            }
        }
    }
    
    func textToSpeech(text: String) {
//        print("Before speak=\(synth.isSpeaking), paused=\(synth.isPaused)")
        
        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }
        
        myUtterance = AVSpeechUtterance(string: text)
        myUtterance.rate = 0.4
        synth.speak(myUtterance)
        
        

//        if synth.isPaused {
//            // continue
//            synth.continueSpeaking()
//        } else if synth.isSpeaking {
//            // pause
//            synth.pauseSpeaking(at: .immediate)
//        } else {
//            // start a new one
//            myUtterance = AVSpeechUtterance(string: text)
//            myUtterance.rate = 0.3
//            synth.speak(myUtterance)
//        }
//        print("After speak=\(synth.isSpeaking), paused=\(synth.isPaused)")
    }
    
    func stopSpeech(){
        // cleanup
        recognitionTask?.cancel()
        recognitionTask?.finish()
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request.endAudio()
        
        startButton.setTitle("Start", for: .normal)
    }
    
    func startSPeechDelayTimerToStop() -> Timer {
        if timerToStopSpeech.isValid { timerToStopSpeech.invalidate() }
//        timerToStopSpeech?.invalidate()
        return Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (Timer) in
            self.stopSpeech()
        })
    }
}

