//
//  SecondViewController.swift
//  TestIncoming
//
//  Created by Lokeshwaran on 02/04/24.
//


// io error , unauthorized error should not log in


import UIKit
import linphonesw
import AVFoundation
import CoreVideo
import AVKit

class SecondViewController: UIViewController,CallManagerDelegate, RegistrationStateDelegate
{
    weak var registrationStateDelegate: RegistrationStateDelegate?
    
    var receivedData: String?
    var sipadd: String?
    
    
    
    // Timer properties
    var timer: Timer?
    var callStartTime: Date?
    
    
    
    //Outgoing call outlets
    @IBOutlet weak var HeadLbl: UILabel!
    @IBOutlet weak var CallSIP: UITextField!
    
    //View outlets
    @IBOutlet weak var SecViewOne: UIView!
    @IBOutlet weak var SecViewTwo: UIView!
    
    //Incoming call outlets
    @IBOutlet weak var AcceptCall: UIButton!
    @IBOutlet weak var DeclineCall: UIButton!
    @IBOutlet weak var Speaker: UIButton!
    @IBOutlet weak var Mic: UIButton!
    
    //video call button
    @IBOutlet weak var camera: UIButton!
    
    //Call dutaiton lbl
    @IBOutlet weak var CallDuration: UILabel!
    
    
    //Status view
    @IBOutlet weak var StatusView: UIView!
    
    
    //view 1 lbl
    @IBOutlet weak var LoginSts: UILabel!
    
    
    //view 2 lbl
    @IBOutlet weak var callerid: UILabel!
    
    
    //view 3 lbl
    @IBOutlet weak var imcominglbl: UILabel!
    
    
    //Registration state
    @IBOutlet weak var reglbl: UILabel!
    
    //switch Camera
    @IBOutlet weak var SwitchCamera: UIButton!
    
    //Show video ui 1
    @IBOutlet weak var VideoUi: UIView!
    
    //Show video ui 2
    @IBOutlet weak var VideoUi2: UIView!
    
    
    @IBOutlet weak var timelbl: UILabel!
    
    
    var callManager = CallManager()
    
    
    var localVideoView: UIView?
    var remoteVideoView: UIView?

    

    //viewWillDisappear func (back button log out)
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent
        {
            // Logout the user
            callManager.unregister()
            callManager.delete()
        }
    }
    
    
    //ViewDidLoad func
    override func viewDidLoad()
    {
        
        super.viewDidLoad()
        
        localVideoView = VideoUi
        remoteVideoView = VideoUi2
        
        //To show the local video in the UI View(VideoUi view)
        callManager.mCore.nativeVideoWindow = localVideoView
        
        //Tp show the remote viewo in the UI View(VideoUi2 view)
        callManager.mCore.nativePreviewWindow = remoteVideoView
        
        
        //keyboard tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        
        print("sipadd",sipadd!)
        
        //Delegate call for registration status
        callManager.registrationStateDelegate = self
        
        //Delegate call for call status
        callManager.delegate = self
        
        //To hide view 2
        SecViewTwo.isHidden = true
        
        SecViewOne.layer.cornerRadius = 20
        SecViewTwo.layer.cornerRadius = 20
        StatusView.layer.cornerRadius = 30
        
        //To print the user name
        if let username = receivedData
        {
            HeadLbl.text = "\(username)"
        }
        else
        {
            HeadLbl.text = "Please Login"
        }
        
        callManager.callStateDidChange = { [weak self] state in
            self?.updateCallStateLabel(state: state)
            
        }
        
        VideoUi.isHidden = true
        VideoUi2.isHidden = true
    }

    //Keyboard disable when touch
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }

    //MARK: - Outgoing call
    @IBAction func Call(_ sender: Any)
    {
        SecViewTwo.isHidden = false
        AcceptCall.isHidden = false
        DeclineCall.isHidden = false
        Speaker.isHidden = false
        Mic.isHidden = false
        camera.isHidden = false
        SwitchCamera.isHidden = false
        
        // If there's an ongoing call, terminate it
        if callManager.isCallRunning
        {
            callManager.terminateCall()
        }
        else
        {
            // Start outgoing call
            callManager.outgoingCall()
            
            // Pass remote address for outgoing call
            if let remote = CallSIP.text
            {
                let abc = sipadd!
                let sipNumber = "sip:\(remote)@\(abc)"
                //let sipNumber = "sip:\(remote)@10.10.1.126"
                callManager.passremote(remoteAddress: sipNumber)
                print("sipnumber",sipNumber)
            }
        }
        
        if CallSIP.text == ""
        {
            CallAlert(message: "Enter SIP")
        }
    }
    
    //MARK: - Accept call
    @IBAction func AcceptCall(_ sender: Any)
    {
        callManager.acceptCall()
        print("Call Accepted..........")
        Mic.isHidden = false
        Speaker.isHidden = false
        camera.isHidden = false
        SwitchCamera.isHidden = false
                
    }
    
    //MARK: - Decline call
    
    @IBAction func DeclineCall(_ sender: Any)
    {
        
        callManager.terminateCall()
        print("Call Declined.........")
        SecViewTwo.isHidden = true
        
        VideoUi.isHidden = true
        VideoUi2.isHidden = true
    }
    
    //MARK: - Speaker toggle
    
    @IBAction func Speaker(_ sender: UIButton)
    {
        callManager.toggleSpeaker()
        
        //if selected highlighted else not highlighted
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected
        {
            sender.backgroundColor = .blue
        }
        else
        {
            sender.backgroundColor = .clear
        }
    }
    
    //MARK: - Mic on/off
    
    //Mic
    @IBAction func Mic(_ sender: UIButton)
    {
        callManager.muteMicrophone()
        
        //if selected highlighted else not highlighted
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected
        {
            sender.backgroundColor = .blue
        }
        
        else
        {
            sender.backgroundColor = .clear
        }
    }

    //MARK: - Turn on video button
    
    @IBAction func camera(_ sender: UIButton)
    {
        if callManager.isVideoEnabled
        {
            callManager.toggleVideo()
            print("Video enable")
        }
        else
        {
            callManager.toggleVideo()
            print("Video Disabled")
        }
        
        //If clicked button will get hilighted
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected
        {
            sender.backgroundColor = .blue
        }
        
        else
        {
            sender.backgroundColor = .clear
        }
    }
    
    //MARK: - Front and back camera toggle
    
    @IBAction func SwitchCamera(_ sender: UIButton)
    {
        callManager.toggleCamera()
        
        //If selected button will hilighted
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected
        {
            sender.backgroundColor = .blue
        }
        
        else
        {
            sender.backgroundColor = .clear
        }
    }
    
    //MARK: - Enter sip address (Alert)
    
    //Alert func
    func CallAlert(message: String)
    {
        let alert = UIAlertController(title: "Enter SIP", message: "Enter Caller ID", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default,handler: nil))
        present(alert,animated: true,completion: nil)
    }
    
    //Call state
    func saveCallManagerState()
    {
        UserDefaults.standard.set(callManager.username, forKey: "username")
        UserDefaults.standard.set(callManager.passwd, forKey: "password")
        UserDefaults.standard.set(callManager.domain, forKey: "domain")
    }
    
    //Call state statements
    func updateCallStateLabel(state: Call.State)
    {
        switch state
        {
        case .Idle:
            LoginSts.text = "Idle"
            CallDuration.text = "00:00"
            
        case .IncomingReceived:
            LoginSts.text = "Incoming call received"
            SecViewTwo.isHidden = false
            Mic.isHidden = true
            Speaker.isHidden = true
            camera.isHidden = true
            SwitchCamera.isHidden = true
            
            
        case .OutgoingInit:
            LoginSts.text = "Outgoing call initializing"
            
        case .OutgoingProgress:
            LoginSts.text = "Outgoing call in progress"
            
        case .OutgoingRinging:
            LoginSts.text = "Outgoing call ringing"
            
        case .OutgoingEarlyMedia:
            LoginSts.text = "Outgoing call with early media"
            
        case .Connected:
            LoginSts.text = "Connected"
            LoginSts.textColor = .green
            
        case .StreamsRunning:
            LoginSts.text = "Streams running"
            LoginSts.textColor = .systemGreen
            
            startCallTimer()
            
        case .Pausing:
            LoginSts.text = "Pausing"
            
        case .Paused:
            LoginSts.text = "Paused"
            
        case .Resuming:
            LoginSts.text = "Resuming"
            
        case .Referred:
            LoginSts.text = "Referred"
            
        case .Error:
            LoginSts.text = "Error"
            
        case .End:
            LoginSts.text = "Call ended"
            LoginSts.textColor = .red
            
        case .Released:
            LoginSts.text = "Call released"
            SecViewTwo.isHidden = true
            LoginSts.textColor = .red
            
            stopCallTimer()
            
        default:
            LoginSts.text = "Unknown"
        }
    }
    
    // Call state change handler
    func callStateDidChange(state: linphonesw.Call.State)
    {
        //to show the call status in the update label
        updateCallStateLabel(state: state)
        
        if state == .Connected || state == .StreamsRunning
        {
            if callManager.isVideoEnabled
            {
                localVideoView?.isHidden = false
                remoteVideoView?.isHidden = false
            }
            
            else
            {
                localVideoView?.isHidden = true
                remoteVideoView?.isHidden = true
            }
            startCallTimer()
        }
    }
    
    //MARK: - To show the registration state
    func registrationStateChanged(message: String, state: RegistrationState)
    {
        registrationStateDelegate?.registrationStateChanged(message: message, state: state)
        print("Received registration state message: \(message), state: \(state)")
        
        DispatchQueue.main.async { [weak self] in
            self?.reglbl.text = "Status: \(state), Message: \(message)"
        }
    }
    
    //MARK: - Call Duration
    
    var secondsElapsed: Int = 0
    @objc func updateCallDurationLabel()
    {
        secondsElapsed += 1
        let minutes = secondsElapsed / 60
        let seconds = secondsElapsed % 60
        CallDuration.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
//    func startCallTimer()
//    {
//        // Stop any previous timer
//        timer?.invalidate()
//        // Reset elapsed time
//        secondsElapsed = 0
//        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCallDurationLabel), userInfo: nil, repeats: true)
//    }
    
    func startCallTimer() {
        stopCallTimer() // Stop any previous timer
        secondsElapsed = 0 // Reset elapsed time
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCallDurationLabel), userInfo: nil, repeats: true)
    }
    
    func stopCallTimer()
    {
        timer?.invalidate()
        timer = nil
        CallDuration.text = ""
    }
        
}

