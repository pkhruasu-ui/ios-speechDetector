//
//  ViewController.swift
//  SpeechDetector
//
//  Created by Khruasuwan, Prajak(AWF) on 3/5/18.
//  Copyright © 2018 Khruasuwan, Prajak(AWF). All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    //MARK: Properties
    
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var detectedTextLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    
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
            try audioEngine.start()
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

                // change color base on the last text output
                var lastString: String = ""
                for segment in result.bestTranscription.segments {
                    let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                    lastString = String(bestString[indexTo...])
                }
                
                self.checkForColorsSaid(resultString: lastString)
                
            } else if let error = error {
                print(error)
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
}

