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
    
    
    var callManager = CallManager()
    
    
    //new variables for the video call
    private var callerVideoView: UIView?
    private var calleeVideoView: UIView?
    private var callerVideoLayer: AVCaptureVideoPreviewLayer?
    private var calleeVideoLayer: AVCaptureVideoPreviewLayer?
    private var callerVideoSession: AVCaptureSession?
    private var calleeVideoSession: AVCaptureSession?
    
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
        
        
        print("ssssss",sipadd!)
        
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
        
        //lw
        //setupVideoViews()
        
        VideoUi.isHidden = true
        VideoUi2.isHidden = true
        //setupVideoViews()
        
    }

    //Keyboard func
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
    
    //Incoming call
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
                print("ssssss",sipNumber)
            }
            
            //            let remote = CallSIP.text
            //            callManager.passremote(remoteAddress: remote!)
            
            
        }
        
        if CallSIP.text == ""
        {
            CallAlert(message: "Enter SIP")
        }
    }
    
    //Accept call
    @IBAction func AcceptCall(_ sender: Any)
    {
        callManager.acceptCall()
        print("Call Accepted..........")
        Mic.isHidden = false
        Speaker.isHidden = false
        camera.isHidden = false
        SwitchCamera.isHidden = false
        
        logVideoSessionAndLayerStates()
        
    }
    //Decline call
    @IBAction func DeclineCall(_ sender: Any)
    {
        callManager.terminateCall()
        print("Call Declined.........")
        SecViewTwo.isHidden = true
        
        //loga
        //stopCallTimer()
        VideoUi.isHidden = true
        VideoUi2.isHidden = true
        
    }
    
    //Speaker
    @IBAction func Speaker(_ sender: UIButton)
    {
        callManager.toggleSpeaker()
        
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
    
    //Mic
    @IBAction func Mic(_ sender: UIButton)
    {
        callManager.muteMicrophone()
        
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
    
    
    
    @IBAction func camera(_ sender: UIButton)
    {
        if callManager.isVideoEnabled
        {
            callManager.toggleVideo()
            print("aaaaa Video enable")
            
            // Set up AVCaptureSession when view loads
            //setupCaptureSession()
            
            //Video call function call
            //            VideoUi.isHidden = false
            //            VideoUi2.isHidden = false
            
            
            //lw
            //setupVideoViews()
            
        }
        else
        {
            callManager.toggleVideo()
            print("aaaaaa Video Disabled")
            
            
            //            VideoUi.isHidden = true
            //            VideoUi2.isHidden = true
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
        
        
        logVideoSessionAndLayerStates()
        
        // Toggle the button's selected state
        //sender.isSelected = !sender.isSelected
        //sender.backgroundColor = sender.isSelected ? .blue : .clear
    }
    
    
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
    
    //State statements
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
        
        logVideoSessionAndLayerStates()
        updateCallStateLabel(state: state)
        
        // Show or hide VideoUi based on call state
        //        if callManager.isVideoEnabled
        //        {
        //                // Video is enabled, start the video sessions
        //                callerVideoSession?.startRunning()
        //                calleeVideoSession?.startRunning()
        //
        //                // Show the caller and callee video views
        //                callerVideoView?.isHidden = false
        //                calleeVideoView?.isHidden = false
        //        }
        //        else
        //        {
        //                // Video is disabled, stop the video sessions
        //                callerVideoSession?.stopRunning()
        //                calleeVideoSession?.stopRunning()
        //
        //                // Hide the caller and callee video views
        //                callerVideoView?.isHidden = true
        //                calleeVideoView?.isHidden = true
        //        }
        //
        //        if state == .End || state == .Released
        //        {
        //            // Stop the timer when the call ends or is released
        //            stopCallTimer()
        //        }
        
        if state == .Connected || state == .StreamsRunning
        {
            if callManager.isVideoEnabled
            {
                // Video is enabled, start the video sessions
                callerVideoSession?.startRunning()
                calleeVideoSession?.startRunning()
                
                // Show the caller and callee video views
//                callerVideoView?.isHidden = false
//                calleeVideoView?.isHidden = false
                
                localVideoView?.isHidden = false
                remoteVideoView?.isHidden = false
            }
            else
            {
                // Video is disabled, hide the video views
//                callerVideoView?.isHidden = true
//                calleeVideoView?.isHidden = true
                localVideoView?.isHidden = true
                remoteVideoView?.isHidden = true
            }
            startCallTimer()
        }
        else if state == .IncomingReceived || state == .OutgoingInit || state == .OutgoingProgress || state == .OutgoingRinging || state == .OutgoingEarlyMedia
        {
            // Call is in progress, but video is not enabled yet
            callerVideoView?.isHidden = true
            calleeVideoView?.isHidden = true
        }
        else if state == .End || state == .Released
        {
            // Call has ended, hide the video views
            callerVideoView?.isHidden = true
            calleeVideoView?.isHidden = true
            
            // Stop the timer when the call ends or is released
            stopCallTimer()
        }
        else
        {
            // Other call states, hide the video views
            callerVideoView?.isHidden = true
            calleeVideoView?.isHidden = true
        }
        
        
        
    }
    
    
    func logVideoSessionAndLayerStates() {
        print("loga Caller video session state: \(callerVideoSession?.isRunning ?? false)")
        print("loga Callee video session state: \(calleeVideoSession?.isRunning ?? false)")
        print("loga Caller video layer state: \(callerVideoLayer?.isHidden ?? true)")
        print("loga Callee video layer state: \(calleeVideoLayer?.isHidden ?? true)")
        
        
        print("loga Caller video session: \(callerVideoSession.debugDescription)")
        print("loga Callee video session: \(calleeVideoSession.debugDescription)")
        print("loga Caller video layer: \(callerVideoLayer.debugDescription)")
        print("loga Callee video layer: \(calleeVideoLayer.debugDescription)")
    }
    
    
    //To show the registration state
    func registrationStateChanged(message: String, state: RegistrationState)
    {
        registrationStateDelegate?.registrationStateChanged(message: message, state: state)
        print("Received registration state message: \(message), state: \(state)")
        
        DispatchQueue.main.async { [weak self] in
            self?.reglbl.text = "Status: \(state), Message: \(message)"
        }
        
        
        if message == "io error"
        {
            print("page2 io error")
        }
        
        if message == "Unauthorized"
        {
            print("page2 unnnnn")
        }
        
        if message == "Registration impossible"
        {
            print("page2 imposible")
        }
        
        // use this if this is passed only we should navigate to the second page else not.
        if message == "Registration successful"
        {
            print("page2 success")
        }
        
    }
    
    var secondsElapsed: Int = 0
    @objc func updateCallDurationLabel()
    {
        secondsElapsed += 1
        let minutes = secondsElapsed / 60
        let seconds = secondsElapsed % 60
        CallDuration.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    func startCallTimer()
    {
        timer?.invalidate() // Stop any previous timer
        secondsElapsed = 0 // Reset elapsed time
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCallDurationLabel), userInfo: nil, repeats: true)
    }
    
    func stopCallTimer()
    {
        timer?.invalidate()
        CallDuration.text = ""
    }
    
    
    //MARK: To show video in the UI
    
    
    //    func setupVideoViews() {
    //        callerVideoView = VideoUi
    //        calleeVideoView = VideoUi2
    //
    //        // Set up the caller video layer
    //        if let callerVideoSession = callManager.callerVideoSession {
    //            callerVideoLayer = AVCaptureVideoPreviewLayer(session: callerVideoSession)
    //            callerVideoLayer?.frame = callerVideoView?.bounds ?? .zero
    //            callerVideoLayer?.videoGravity = .resizeAspectFill
    //            callerVideoView?.layer.addSublayer(callerVideoLayer!)
    //        }
    //
    //        // Set up the callee video layer
    //        if let calleeVideoSession = callManager.calleeVideoSession {
    //            calleeVideoLayer = AVCaptureVideoPreviewLayer(session: calleeVideoSession)
    //            calleeVideoLayer?.frame = calleeVideoView?.bounds ?? .zero
    //            calleeVideoLayer?.videoGravity = .resizeAspectFill
    //            calleeVideoView?.layer.addSublayer(calleeVideoLayer!)
    //        }
    //    }
    
    //lw
    //    func setupVideoViews() {
    //        callerVideoView = VideoUi
    //        calleeVideoView = VideoUi2
    //
    //        // Set up the caller video layer
    //        if let callerVideoSession = callManager.callerVideoSession {
    //            callerVideoLayer = AVCaptureVideoPreviewLayer(session: callerVideoSession)
    //            callerVideoLayer?.frame = callerVideoView?.bounds ?? .zero
    //            callerVideoLayer?.videoGravity = .resizeAspectFill
    //            callerVideoView?.layer.addSublayer(callerVideoLayer!)
    //        }
    //
    //        // Set up the callee video layer
    //        if let calleeVideoSession = callManager.calleeVideoSession {
    //            calleeVideoLayer = AVCaptureVideoPreviewLayer(session: calleeVideoSession)
    //            calleeVideoLayer?.frame = calleeVideoView?.bounds ?? .zero
    //            calleeVideoLayer?.videoGravity = .resizeAspectFill
    //            calleeVideoView?.layer.addSublayer(calleeVideoLayer!)
    //        }
    //    }
    
    
    //new method without uisng the wrapperclass.(not working, video is getting stuck)
    
    //    func setupVideoViews()
    //    {
    //        callerVideoView = VideoUi
    //        calleeVideoView = VideoUi2
    //
    //        // Set up the caller video session and layer
    //        callerVideoSession = AVCaptureSession()
    //        callerVideoSession?.sessionPreset = .medium
    //
    //        // Add the video input device
    //        if let callerDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    //        {
    //            do
    //            {
    //                let callerInput = try AVCaptureDeviceInput(device: callerDevice)
    //                callerVideoSession?.addInput(callerInput)
    //            }
    //            catch
    //            {
    //                print("Error setting up caller video session: \(error)")
    //            }
    //        }
    //
    //        // Add the video output
    //        let callerVideoOutput = AVCaptureVideoDataOutput()
    //        callerVideoSession?.addOutput(callerVideoOutput)
    //
    //        // Create the caller video layer
    //        callerVideoLayer = AVCaptureVideoPreviewLayer(session: callerVideoSession!)
    //        callerVideoLayer?.frame = callerVideoView?.bounds ?? .zero
    //        callerVideoLayer?.videoGravity = .resizeAspectFill
    //        callerVideoView?.layer.addSublayer(callerVideoLayer!)
    //
    //        // Set up the callee video session and layer
    //        calleeVideoSession = AVCaptureSession()
    //        calleeVideoSession?.sessionPreset = .medium
    //
    //        // Add the video input device
    //        if let calleeDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    //        {
    //            do
    //            {
    //                let calleeInput = try AVCaptureDeviceInput(device: calleeDevice)
    //                calleeVideoSession?.addInput(calleeInput)
    //            }
    //            catch
    //            {
    //                print("Error setting up callee video session: \(error)")
    //            }
    //        }
    //
    //        // Add the video output
    //        let calleeVideoOutput = AVCaptureVideoDataOutput()
    //        calleeVideoSession?.addOutput(calleeVideoOutput)
    //
    //        // Create the callee video layer
    //        calleeVideoLayer = AVCaptureVideoPreviewLayer(session: calleeVideoSession!)
    //        calleeVideoLayer?.frame = calleeVideoView?.bounds ?? .zero
    //        calleeVideoLayer?.videoGravity = .resizeAspectFill
    //        calleeVideoView?.layer.addSublayer(calleeVideoLayer!)
    //
    //        logVideoSessionAndLayerStates()
    //    }
    
   
    
}

