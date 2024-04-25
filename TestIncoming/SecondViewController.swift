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
    // Weak reference to a registration state delegate.
    weak var registrationStateDelegate: RegistrationStateDelegate?
    var vc = ViewController()
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
    // Override function called when the view is about to disappear from the screen.
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        // Check if the view controller is being popped from the navigation stack.
        if isMovingFromParent
        {
            // If the view controller is being popped, perform logout actions.
            logout()
            // Reset the registration state handling and call manager of the first view controller.
            if let viewController = navigationController?.viewControllers.first as? ViewController {
                viewController.isRegistrationStateHandled = false
                viewController.shouldResetCallManager = true
            }
        }
    }
    
    //MARK: - ViewDidLoad
    override func viewDidLoad()
    {
        super.viewDidLoad()
        localVideoView = VideoUi
        remoteVideoView = VideoUi2
        //the local video in the UI View(VideoUi view)
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
        reglbl.isHidden = true
    }
    
    //MARK: - Outgoing call
    @IBAction func Call(_ sender: Any)
    {
        //If outgoing call is performed accept, decline, speaker, mic, vidoe, camera will be visible.
        SecViewTwo.isHidden = false
        AcceptCall.isHidden = false
        DeclineCall.isHidden = false
        Speaker.isHidden = true
        Mic.isHidden = true
        camera.isHidden = true
        SwitchCamera.isHidden = true

        //Pass remote address for outgoing call
        //User types only 4000. eg it converts into "sip:4000@10.10.1.126"
        if let remote = CallSIP.text
        {
            let abc = sipadd!
            let sipNumber = "sip:\(remote)@\(abc)"
            //let sipNumber = "sip:\(remote)@10.10.1.126"
            callManager.passremote(remoteAddress: sipNumber)
            callManager.outgoingCall()
            print("sipnumber",sipNumber)
        }
        if CallSIP.text == ""
        {
            //if sip adrress is empty alert will shown
            CallAlert(message: "Enter SIP")
            SecViewTwo.isHidden = true
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
        resetVideoViews()
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

 //MARK: - Call States(enums)
    func updateCallStateLabel(state: Call.State)
    {
        switch state
        {
        case .Idle:
            LoginSts.text = "Idle"
            CallDuration.text = "00:00"
            //To hide the video views
            resetVideoViews()
            resetButtonStates()
            
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
            //Show video views when call is connected
            VideoUi.isHidden = !callManager.isVideoEnabled
            VideoUi2.isHidden = !callManager.isVideoEnabled
            
        case .StreamsRunning:
            LoginSts.text = "Streams running"
            LoginSts.textColor = .systemGreen
            //Show video views when call stream are running
            VideoUi.isHidden = !callManager.isVideoEnabled
            VideoUi2.isHidden = !callManager.isVideoEnabled
            Mic.isHidden = false
            Speaker.isHidden = false
            camera.isHidden = false
            SwitchCamera.isHidden = false
            
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
            resetButtonStates()
            //To hide the video views
            resetVideoViews()
            
        case .Released:
            LoginSts.text = "Call released"
            SecViewTwo.isHidden = true
            LoginSts.textColor = .red
            stopCallTimer()
            localVideoView?.isHidden = true
            remoteVideoView?.isHidden = true
            resetButtonStates()
            //To hide the video views
            resetVideoViews()
            
        default:
            LoginSts.text = "Unknown"
        }
    }
    
    // Call state change handler
    // Function called when the call state changes
    func callStateDidChange(state: linphonesw.Call.State)
    {
        // Update the call status label based on the new call state.
        updateCallStateLabel(state: state)
        // Check if the call state is connected or streams running.
            // If video is enabled, show the local and remote video views; otherwise, hide them.
            if state == .Connected || state == .StreamsRunning {
                if callManager.isVideoEnabled {
                    // If video is enabled, show the local and remote video views.
                    localVideoView?.isHidden = false
                    remoteVideoView?.isHidden = false
                } else {
                    // If video is not enabled, hide the local and remote video views.
                    localVideoView?.isHidden = true
                    remoteVideoView?.isHidden = true
                }
                
                // Start the call timer to track call duration.
                startCallTimer()
                
                // Print a message for debugging purposes.
                print("findme call state changed \(state)")
        }
    }
    
    //MARK: - To show registration state
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
    // Variable to track the number of seconds elapsed during the call.
    var secondsElapsed: Int = 0
    // Function called by the timer to update the call duration label.
    @objc func updateCallDurationLabel()
    {
        // Get the call duration from the CallManager.
        let callDuration = callManager.getCallDuration()
        // Calculate minutes and seconds from the total elapsed seconds.
        let minutes = secondsElapsed / 60
        let seconds = secondsElapsed % 60
        // Update the CallDuration label with the formatted duration string (mm:ss).
        CallDuration.text = String(format: "%02d:%02d", minutes, seconds)
        // Print the current call duration for debugging purposes.
        print("findme",CallDuration.text!)
        // Increment the seconds elapsed for the next update.
        secondsElapsed += 1
    }
    //MARK: - To start call timer
    func startCallTimer()
    {
        // Only start the timer if it's not already running
        if timer == nil || !timer!.isValid
        {
            // Reset elapsed time
            secondsElapsed = 0
            
            // Start a new timer
            // Create a new timer object using the scheduledTimer method.
            // This method creates a timer that fires events at regular intervals.
            // Parameters:
            // - timeInterval: The time interval between each firing of the timer, in seconds.
            // - target: The object that will receive the specified selector message when the timer fires.
            // - selector: The selector to call on the target object when the timer fires.
            // - userInfo: Any additional information to pass to the target object when the timer fires. (In this case, it's set to nil.)
            // - repeats: A Boolean value indicating whether the timer should repeatedly reschedule itself after firing. (In this case, it's set to true, meaning the timer will keep running until explicitly stopped.)
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCallDurationLabel), userInfo: nil, repeats: true)
            print("Timer started")
        }
    }
    //MARK: - To Stop call timer
    func stopCallTimer()
    {
        // Invalidate the timer to stop it from firing events.
        timer?.invalidate()
        // Set the timer to nil to release its reference.
        timer = nil
        //Clear the text in the CallDuration label.
        CallDuration.text = ""
    }
    //MARK: - TO reset the button states
    func resetButtonStates()
    {
        Mic.isSelected = false
        Speaker.isSelected = false
        camera.isSelected = false
        SwitchCamera.isSelected = false
        Mic.backgroundColor = .clear
        Speaker.backgroundColor = .clear
        camera.backgroundColor = .clear
        SwitchCamera.backgroundColor = .clear
    }
    //MARK: - To reset the video views
    func resetVideoViews()
    {
        //Hide the video views
        VideoUi.isHidden = true
        VideoUi2.isHidden = true
    }
    //MARK: - Logout
    func logout()
    {
        //Clear stored credentials
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "password")
        UserDefaults.standard.removeObject(forKey: "domain")
        
        //Reset authentication state
        callManager.loggedIn = false
        
        //Unregister and delete call manager
        callManager.unregister()
        callManager.delete()
    }
    
    // Function to dismiss the keyboard when tapped outside of a text field.
    @objc func dismissKeyboard() 
    {
        // Call the endEditing method on the view to dismiss the keyboard.
        // Passing true as the argument resigns the first responder status from any responder in the view's hierarchy.
        view.endEditing(true)
    }

}
