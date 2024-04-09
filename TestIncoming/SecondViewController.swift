//
//  SecondViewController.swift
//  TestIncoming
//
//  Created by Lokeshwaran on 02/04/24.
//


// io error , unauthorized error should not log in


import UIKit
import linphonesw

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
    

    var callManager = CallManager()
    

    //ViewDidLoad func (back button log out)
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
        
        // Start call timer
        //loga
        //startCallTimer()
        
    }
    
        //Accept call
        @IBAction func AcceptCall(_ sender: Any)
        {
            callManager.acceptCall()
            print("Call Accepted..........")
            Mic.isHidden = false
            Speaker.isHidden = false
            
            //loga
            //startCallTimer()

        }
        
        //Decline call
        @IBAction func DeclineCall(_ sender: Any)
        {
            callManager.terminateCall()
            print("Call Declined.........")
            SecViewTwo.isHidden = true
            
            //loga
            //stopCallTimer()

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
    
    //OLD FUCNTION
//    //To show the state
//    func callStateDidChange(state: linphonesw.Call.State)
//    {
//         updateCallStateLabel(state: state)
//    }
    
    // Call state change handler
    func callStateDidChange(state: linphonesw.Call.State) {
        updateCallStateLabel(state: state)
        if state == .End || state == .Released {
            stopCallTimer() // Stop the timer when the call ends or is released
        }
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
    
    }

