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
    
    
    //Outgoing call outlets
    @IBOutlet weak var HeadLbl: UILabel!
    //To get the SIP address and perform call
    @IBOutlet weak var CallSIP: UITextField!
    //outgoing call view
    @IBOutlet weak var SecViewOne: UIView!
    //call view - consists of accept, declin, speaker, mic, video, camera
    @IBOutlet weak var SecViewTwo: UIView!
    //Accept call
    @IBOutlet weak var AcceptCall: UIButton!
    //Decline call
    @IBOutlet weak var DeclineCall: UIButton!
    //Speaker button
    @IBOutlet weak var Speaker: UIButton!
    //Mic button
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
    //timelbl
    @IBOutlet weak var timelbl: UILabel!
    
    //Create an instance of CallManager to manage calls
    var callManager = CallManager()
    //Bringing data from page 1 to page 2 (to show the user name eg. 4000)
    var receivedData: String?
    var sipadd: String?
    //Timer properties
    var timer: Timer?
    //Local video view
    var localVideoView: UIView?
    //Remote video view
    var remoteVideoView: UIView?

//MARK: - ViewWillDisapper
    //ViewWillDisappear func (back button log out)
    //Using this to unregister the user
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        if isMovingFromParent
        {
            //Unregister the user
            callManager.unregister()
            callManager.delete()
        }
        
    }
    //MARK: - ViewDidLoad
    override func viewDidLoad()
    {
        super.viewDidLoad()
        localVideoView = VideoUi
        remoteVideoView = VideoUi2
        //To show the local video in the UI View(VideoUi view)
        callManager.mCore.nativeVideoWindow = localVideoView
        //To show the remote viewo in the UI View(VideoUi2 view)
        callManager.mCore.nativePreviewWindow = remoteVideoView
        //keyboard tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        //To print the SIP address
        print("sipadd",sipadd!)
        //Delegate call for registration status
        callManager.registrationStateDelegate = self
        //Delegate call for call status
        callManager.delegate = self
        //To hide view 2
        SecViewTwo.isHidden = true
        //Setting corner radius for all views
        SecViewOne.layer.cornerRadius = 20
        SecViewTwo.layer.cornerRadius = 20
        StatusView.layer.cornerRadius = 30
        //To print the user name (what we type in the page 1 will show here)
        if let username = receivedData
        {
            HeadLbl.text = "\(username)"
        }
        else
        {
            HeadLbl.text = "Please Login"
        }
        // Assigning a closure to callManager's callStateDidChange property.
        // This closure will be executed when the call state changes.
        callManager.callStateDidChange = { [weak self] state in
        // Updating the call state label in the SecondViewController
        // using the updateCallStateLabel method.
        self?.updateCallStateLabel(state: state)
        }
        //Initially to hide the views
        VideoUi.isHidden = true
        VideoUi2.isHidden = true
        
        
        
    }

    //Keyboard disable when touch anywhere
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }

    //MARK: - Outgoing call
    @IBAction func Call(_ sender: Any)
    {
        //If outgoing call is performed accept, decline, speaker, mic, vidoe, camera will visible.
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
            //Start outgoing call
            callManager.outgoingCall()
            //Pass remote address for outgoing call
            //User types only 4000 eg it converts into "sip:4000@10.10.1.126"
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
            //if sip adrress is empty alert will shown
            CallAlert(message: "Enter SIP")
        }
    }
    
    //MARK: - Accept call
    @IBAction func AcceptCall(_ sender: Any)
    {
        //accept call
        callManager.acceptCall()
        print("Call Accepted..........")
        //after accepting call mic, speaker, video, camera will be visible
        Mic.isHidden = false
        Speaker.isHidden = false
        camera.isHidden = false
        SwitchCamera.isHidden = false
                
    }
    
    //MARK: - Decline call
    
    @IBAction func DeclineCall(_ sender: Any)
    {
        //end call
        callManager.terminateCall()
        print("Call Declined.........")
        //hide call view
        SecViewTwo.isHidden = true
        
        //hide video views
        VideoUi.isHidden = true
        VideoUi2.isHidden = true
    }
    
    //MARK: - Speaker toggle
    @IBAction func Speaker(_ sender: UIButton)
    {
        //Toggle the speaker mode on or off using the CallManager
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
    @IBAction func Mic(_ sender: UIButton)
    {
        //Toggle the mic mode on or off using the CallManager
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
        //Toggle the Video mode on or off using the CallManager
        callManager.toggleVideo()
        //If selected shows in blue else in clear
        if callManager.isVideoEnabled
        {
            print("Video enable")
            sender.backgroundColor = .blue
        }
        else
        {
            print("Video Disabled")
            sender.backgroundColor = .clear
        }
        //Call timer continues
        if timer == nil
        {
            startCallTimer()
        }
    }
    
    //MARK: - Front and back camera toggle
    @IBAction func SwitchCamera(_ sender: UIButton)
    {
        //Toggle the Camera mode, front or back using the CallManager
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
            localVideoView?.isHidden = true
            remoteVideoView?.isHidden = true
            
        default:
            LoginSts.text = "Unknown"
        }
    }
    // Call state change handler
    func callStateDidChange(state: linphonesw.Call.State)
    {
        //To show the call status in the update label
        updateCallStateLabel(state: state)
        //if the call state is connected or streamsruning means video view enabled else disable
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
            print("findme call state changed \(state)")
        }
    }
    
    //MARK: - To show the registration state(Registration successful - key)
    func registrationStateChanged(message: String, state: RegistrationState)
    {
        //Call the registration state delegate method if available
        registrationStateDelegate?.registrationStateChanged(message: message, state: state)
        //Print the received registration state message and state
        print("Lokesh2E Received registration state message: \(message), state: \(state)")
        // Update the UI on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.reglbl.text = "Status: \(state), Message: \(message)"
        }
    }
    
    //MARK: - Call Duration
    var secondsElapsed: Int = 0
    @objc func updateCallDurationLabel()
    {
        let callDuration = callManager.getCallDuration()
        let minutes = secondsElapsed / 60
        let seconds = secondsElapsed % 60
        CallDuration.text = String(format: "%02d:%02d", minutes, seconds)
        print("findme",CallDuration.text!)
        secondsElapsed += 1
    }
    func startCallTimer() 
    {
        // Only start the timer if it's not already running
        if timer == nil || !timer!.isValid 
        {
            // Reset elapsed time
            secondsElapsed = 0
            
            // Start a new timer
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCallDurationLabel), userInfo: nil, repeats: true)
            print("Timer started")
        }
    }
    func stopCallTimer()
    {
        timer?.invalidate()
        timer = nil
        CallDuration.text = ""
    }
}

