//
//  CallManager.swift
//  TestIncoming
//
//  Created by Lokeshwaran on 01/04/24.
//


import linphonesw
import AVFoundation
import CallKit

//Call State
protocol CallManagerDelegate: AnyObject
{
    func callStateDidChange(state: Call.State)
}

//Registeration state
protocol RegistrationStateDelegate: AnyObject 
{
    func registrationStateChanged(message: String, state: RegistrationState)
}


class CallManager {
    
    //Reg
    weak var registrationStateDelegate: RegistrationStateDelegate?
    
    weak var SecondVc : SecondViewController?
    weak var delegate: CallManagerDelegate?
    weak var vc : ViewController?
    
    var callStateDidChange: ((Call.State) -> Void)?
    
    let audioSession = AVAudioSession.sharedInstance()
    
    //video variables
      var callerVideoSession: AVCaptureSession?
      var calleeVideoSession: AVCaptureSession?
    
    var mCore: Core!
    var mAccount: Account?
    var mCoreDelegate: CoreDelegate!
    
    //Login page cred
    var username: String = ""
    var passwd: String = ""
    var domain: String = ""
    var loggedIn: Bool = false
    var transportType: String = "TLS"
    
    
    //Outgoing call related variables
    var callMsg: String = ""
    var isCallRunning: Bool = true
    var canChangeCamera: Bool = false
    var remoteAddress: String = ""
    
    
    //Incoming call related variables
    var isCallIncoming: Bool = false
    var isSpeakerEnabled: Bool = false
    var isMicrophoneEnabled: Bool = false
    var incomingCallMsg: String = ""
    var incomingRemoteAddress: String = "Nobody yet"
    
    //Video call variables
    var call: Call?
    var isVideoEnabled: Bool = false
    
    
    
    //video return

    var activeCalls: [Call] = []

    
    //init
    init()
    {
        
        
        LoggingService.Instance.logLevel = LogLevel.Debug
        
        // Create and start the Core
        do {
            mCore = try Factory.Instance.createCore(configPath: "", factoryConfigPath: "", systemContext: nil)
            try mCore.start()
            
            // Set up delegates
            mCoreDelegate = CoreDelegateStub(onCallStateChanged: { [self] (core: Core, call: Call, state: Call.State, message: String) in
                
                print("Call Status --->:", state)
                delegate?.callStateDidChange(state: state)
                
                //abcvalue = Call.state
                
                print("abc",state)
                self.SecondVc?.updateCallStateLabel(state: state)
                
                // Outgoing call state handling
                if (state == .OutgoingInit)
                {
                    // First state an outgoing call will go through
                }
                
                else if (state == .Connected || state == .StreamsRunning)
                {
                    // When the call is connected or streams are running
                    self.isCallRunning = true
                    self.isVideoEnabled = call.currentParams?.videoEnabled ?? false
                    self.canChangeCamera = core.videoDevicesList.count > 2
                    //print("  call is connecting1")
                }
                
                else if (state == .Released)
                {
                    // Call state will be released shortly after the End state
                    self.isCallRunning = false
                    self.canChangeCamera = false
                    print("find me sip ad --->",self.remoteAddress)
                }
                
                // Incoming call state handling
                if (state == .IncomingReceived)
                {
                    // When a call is received
                    self.isCallIncoming = true
                    self.incomingRemoteAddress = call.remoteAddress!.asStringUriOnly()
                    print("find me call receiving")
                    
                }
                
                else if (state == .Connected || state == .StreamsRunning)
                {
                    // When a call is over
                    self.isCallIncoming = false
                    print("find me call connected")
                    
                }
                
                else if (state == .Released)
                {
                    // When a call is over
                    self.isCallIncoming = false
                    self.incomingRemoteAddress = "Nobody yet"
                    print("find me call disconnected")
                }
                
               
                
                self.callMsg = message
            }, onAccountRegistrationStateChanged: { (core: Core, account: Account, state: RegistrationState, message: String) in
                NSLog("New registration state is \(state) for user id \(String(describing: account.params?.identityAddress?.asString()))\n")
                self.loggedIn = (state == .Ok)
            })
            mCore.addDelegate(delegate: mCoreDelegate)
        }
        
        
        
        catch
        {
            print(error.localizedDescription)
        }
        
        
        
    }
    
    //Login
    func login()
    {
        mCoreDelegate = CoreDelegateStub(onAccountRegistrationStateChanged: { [weak self] (core: Core, account: Account, state: RegistrationState, message: String) in
            // Print the registration state and associated message
            
            print("Registration state lok: \(state), Message: \(message)")
            self?.loggedIn = (state == .Ok)
            
            self?.registrationStateDelegate?.registrationStateChanged(message: message, state: state)
            
            
            //To print the status and the message of the log in user.
            let bcd = message
            let xyz = state
            print("waran(msg)--->",bcd)
            print("waran11(sts)--->",xyz)
            
        })
        mCore.addDelegate(delegate: mCoreDelegate)
        
        //User selecting the type of security layer.
        do {
            var transport: TransportType
            if (transportType == "TLS")
            {
                transport = TransportType.Tls
            }
            else if (transportType == "TCP")
            {
                transport = TransportType.Tcp
            }
            else
            {
                transport = TransportType.Udp
            }
            
            let authInfo = try Factory.Instance.createAuthInfo(username: username, userid: "", passwd: passwd, ha1: "", realm: "", domain: domain)
            
            let accountParams = try mCore.createAccountParams()
            
            
            let identity = try Factory.Instance.createAddress(addr: "sip:\(username)@\(domain)")
            
            
            try accountParams.setIdentityaddress(newValue: identity)
            
            
            let address = try Factory.Instance.createAddress(addr: "sip:\(domain)")
            
            
            try address.setTransport(newValue: transport)
            
            
            try accountParams.setServeraddress(newValue: address)
            
            accountParams.registerEnabled = true
            
            mAccount = try mCore.createAccount(params: accountParams)
            
            mCore.addAuthInfo(info: authInfo)
            
            try mCore.addAccount(account: mAccount!)
            
            mCore.defaultAccount = mAccount
        }
        catch
        {
            print(error.localizedDescription)
        }
    }
    
    //Unregister
    func unregister()
    {
        if let account = mCore.defaultAccount
        {
            let params = account.params
            let clonedParams = params?.clone()
            clonedParams?.registerEnabled = false
            account.params = clonedParams
        }
    }
    
    
    //Delete
    func delete()
    {
        if let account = mCore.defaultAccount
        {
            mCore.removeAccount(account: account)
            mCore.clearAccounts()
            mCore.clearAllAuthInfo()
        }
    }
    
    
    //Outgoing call func
    func outgoingCall()
    {
        do
        {
            let remoteAddress = try Factory.Instance.createAddress(addr: remoteAddress)
            let params = try mCore.createCallParams(call: nil)
            params.mediaEncryption = MediaEncryption.None
            let _ = mCore.inviteAddressWithParams(addr: remoteAddress, params: params)
        }
        catch
        {
            print(error.localizedDescription)
        }
        print("find me **",remoteAddress)
    }
    
    
    //Terminate call
    func terminateCall()
    {
        do
        {
            if (mCore.callsNb == 0)
            {
                return
            }
            try mCore.currentCall?.terminate()
        }
        catch
        {
            print(error.localizedDescription)
        }
    }
    
    
    //Accept call
    func acceptCall()
    {
        // IMPORTANT : Make sure you allowed the use of the microphone (see key "Privacy - Microphone usage description" in Info.plist) !
        do {
            // if we wanted, we could create a CallParams object
            // and answer using this object to make changes to the call configuration
            // (see OutgoingCall tutorial)
            try mCore.currentCall?.accept()
        }
        catch
        { NSLog(error.localizedDescription)
        }
    }
    
    
    //Mic mute & unmute
    func muteMicrophone()
    {
        // The following toggles the microphone, disabling completely / enabling the sound capture
        // from the device microphone
        mCore.micEnabled = !mCore.micEnabled
        isMicrophoneEnabled = !isMicrophoneEnabled
    }
    
    
    //Switch video
    func toggleVideo()
    {
        //        do {
        //            if (mCore.callsNb == 0) { return }
        //            if let call = mCore.currentCall {
        //                let params = try mCore.createCallParams(call: call)
        //                params.videoEnabled = !(call.currentParams!.videoEnabled)
        //                try call.update(params: params)
        //            }
        //        }
        //        catch
        //        {
        //            print(error.localizedDescription)
        //        }
        
        //This function works and old fucntion
        do {
            // Check if there's an ongoing call
            guard let call = mCore.currentCall else {
                print("No ongoing call")
                return
            }
            
            // Create call parameters
            let params = try mCore.createCallParams(call: call)
            
            // Toggle video status
            params.videoEnabled = !call.currentParams!.videoEnabled
            
            // Update call parameters
            try call.update(params: params)
        } catch {
            print("Error toggling video: \(error.localizedDescription)")
        }
        
        if isVideoEnabled {
                isVideoEnabled = false
                stopVideoCaptureSessions()
            } else {
                isVideoEnabled = true
                setupVideoCaptureSessions()
                startVideoCaptureSessions()
            }
    }
    
    
    //Switch camera
    func toggleCamera()
    {
        //        do {
        //            let currentDevice = mCore.videoDevice
        //            for camera in mCore.videoDevicesList {
        //                if (camera != currentDevice && camera != "StaticImage: Static picture") {
        //                    try mCore.setVideodevice(newValue: camera)
        //                    break
        //                }
        //            }
        //        } catch { print(error.localizedDescription) }
        
        
        //This function works and old function
        do {
            // Get available video devices
            let devices = mCore.videoDevicesList
            
            // Get current video device
            let currentDevice = mCore.videoDevice
            
            // Find next available device and switch to it
            if let nextDevice = devices.first(where: { $0 != currentDevice && $0 != "StaticImage: Static picture" })
            {
                try mCore.setVideodevice(newValue: nextDevice)
            }
        }
        catch
        {
            
            print("Error toggling camera: \(error.localizedDescription)")
        }
        
        
        
    }
    
    
    
    //Pause or resume
    func pauseOrResume()
    {
        do {
            if (mCore.callsNb == 0) { return }
            if let call = mCore.currentCall {
                if (call.state != Call.State.Paused && call.state != Call.State.Pausing) {
                    try call.pause()
                } else if (call.state != Call.State.Resuming) {
                    try call.resume()
                }
            }
        } catch { print(error.localizedDescription) }
    }
    
    
    //Speaker
    func toggleSpeaker()
    {
        do {
            // Check if the audio session is currently using the speaker
            if audioSession.currentRoute.outputs.contains(where: { $0.portType == .builtInSpeaker }) {
                // Switch to the receiver
                try audioSession.overrideOutputAudioPort(.none)
            } else {
                // Switch to the speaker
                try audioSession.overrideOutputAudioPort(.speaker)
            }
        } catch {
            print("Error toggling speaker: \(error.localizedDescription)")
        }
    }
    
    
    //Get the username, password, domain from the user
    func setUserCredentials(username: String, password: String, domain: String)
    {
        self.username = username
        self.passwd = password
        self.domain = domain
    }
    
    
    //Get sip address from the user
    func passremote(remoteAddress : String)
    {
        self.remoteAddress = remoteAddress
    }
    
    
    //MARK: Video call
    //NOTE: Changed toggle video and toggle camera
    
    // Method to initiate outgoing video call
    func outgoingVideoCall(remoteAddress: String)
    {
        if let address = try? mCore.createAddress(address: remoteAddress) {
            do {
                // Create call parameters
                let params = try mCore.createCallParams(call: nil)
                
                // Enable video
                params.videoEnabled = true
                
                // Initiate outgoing call
                let _ = mCore.inviteAddressWithParams(addr: address, params: params)
            } catch {
                print("Error initiating outgoing video call: \(error.localizedDescription)")
            }
        } else {
            print("Invalid remote address: \(remoteAddress)")
        }
    }
    
    
    // Method to accept incoming video call
    func acceptVideoCall()
    {
        do
        {
            // Ensure microphone permission is allowed in Info.plist
            try mCore.currentCall?.accept()
        }
        catch
        {
            print("Error accepting incoming video call: \(error.localizedDescription)")
        }
    }
    
    
    // Method to set the local video layer
    // Set up the video capture sessions
    func setupVideoCaptureSessions() {
        // Create the caller video session
        callerVideoSession = AVCaptureSession()
        callerVideoSession?.sessionPreset = .high

        // Create the callee video session
        calleeVideoSession = AVCaptureSession()
        calleeVideoSession?.sessionPreset = .high
        
        print("lokesh Setting up video capture sessions...")

    }

    // Start the video capture sessions
    func startVideoCaptureSessions() {
        if let callerVideoSession = callerVideoSession {
            callerVideoSession.startRunning()
        }

        if let calleeVideoSession = calleeVideoSession {
            calleeVideoSession.startRunning()
        }
        print("lokesh Setting up video capture sessions...")

    }

    // Stop the video capture sessions
    func stopVideoCaptureSessions() {
        if let callerVideoSession = callerVideoSession {
            callerVideoSession.stopRunning()
        }

        if let calleeVideoSession = calleeVideoSession {
            calleeVideoSession.stopRunning()
        }
    }
    
//    var callerVideoSession: AVCaptureSession? 
//    {
//        return self.callerVideoSession
//    }
//
//    var calleeVideoSession: AVCaptureSession? 
//    {
//        return self.calleeVideoSession
//    }
    
    
    //MARK: - Group call feature
    
    // old working methods
    // Method to start a conference call
//        func startConferenceCall(participants: [String]) {
//            // Start calls with each participant
//            for participant in participants {
//                // Create an address for the participant
//                guard let address = try? mCore.createAddress(address: participant) else {
//                    print("Invalid address: \(participant)")
//                    continue
//                }
//
//                // Create call parameters
//                guard let params = try? mCore.createCallParams(call: nil) else {
//                    print("Failed to create call parameters")
//                    continue
//                }
//                
//                // Set media encryption type
//                params.mediaEncryption = MediaEncryption.None
//                
//                // Start the call with the participant
//                if let call = mCore.inviteAddressWithParams(addr: address, params: params) {
//                    // Add the call to the list of active calls
//                    activeCalls.append(call)
//                } else {
//                    print("Failed to start call with: \(participant)")
//                }
//            }
//
//            // Merge calls into a conference
//            if activeCalls.count > 1 {
//                // Merge the calls into a conference using Linphone's API
//                do {
//                    try mCore.enterConference()
//                    print("Conference call started")
//                } catch {
//                    print("Failed to merge calls into a conference: \(error.localizedDescription)")
//                }
//            } else {
//                print("Not enough calls to merge into a conference")
//            }
//        }
//
//        // Method to end the conference call
//        func endConferenceCall() {
//            do {
//                // Leave the conference
//                try mCore.leaveConference()
//                print("Left the conference")
//
//                // Terminate each call in the conference
//                for call in activeCalls {
//                    try call.terminate()
//                }
//
//                // Clear the list of active calls
//                activeCalls.removeAll()
//            } catch {
//                print("Failed to end conference call: \(error.localizedDescription)")
//            }
//        }

    // new method for group call
    
    // Method to start a conference call
        func startConferenceCall(participants: [String]) {
            // Start calls with each participant
            for participant in participants {
                // Create an address for the participant
                guard let address = try? mCore.createAddress(address: participant) else {
                    print("Invalid address: \(participant)")
                    continue
                }

                // Create call parameters
                guard let params = try? mCore.createCallParams(call: nil) else {
                    print("Failed to create call parameters")
                    continue
                }

                // Set media encryption type
                params.mediaEncryption = MediaEncryption.None

                // Start the call with the participant
                guard let call = mCore.inviteAddressWithParams(addr: address, params: params) else {
                    print("Failed to start call with: \(participant)")
                    continue
                }

                // Add the call to the list of active calls
                activeCalls.append(call)
            }

            // Merge the calls into a conference
            mergeActiveCalls()
        }

        // Method to merge active calls into a conference
//    func mergeActiveCallsIntoConference() {
//            // First, check if there are enough active calls
//            guard activeCalls.count >= 2 else {
//                print("Not enough active calls to merge into a conference")
//                return
//            }
//
//            // Ensure all calls are in connected state before merging
//            guard activeCalls.allSatisfy({ $0.state == .StreamsRunning }) else {
//                print("Not all active calls are connected")
//                return
//            }
//
//            // Try merging the active calls
//            do {
//                try mCore.enterConference()
//                print("Calls merged into conference successfully")
//            } catch {
//                print("Failed to merge calls into conference: \(error.localizedDescription)")
//            }
//        }

        // Method to end the conference call
    func endConferenceCall() 
    {
           // Ensure there is an active conference to end
           guard mCore.conference != nil else 
        {
               print("No active conference to end")
               return
           }

           do {
               // Leave the conference
               try mCore.leaveConference()
               print("Left the conference")

               // Terminate each call in the conference
               for call in activeCalls {
                   try call.terminate()
               }

               // Clear the list of active calls
               activeCalls.removeAll()
           } catch {
               print("Failed to end conference call: \(error.localizedDescription)")
           }
       }

    
    func mergeActiveCalls() {
            // Filter and check calls that are in the correct state to be merged
            let callsToMerge = mCore.calls.filter { $0.state == .StreamsRunning }
            
            // Ensure there are at least two active calls to merge
            guard callsToMerge.count >= 2 else {
                print("Not enough active calls to merge")
                return
            }
            
            do {
                // Check if a conference is already active
                if mCore.conference != nil {
                    // Conference is active, so add calls to the existing conference
                    for call in callsToMerge {
                        if call.conference == nil {
                            // Call is not in the conference yet, so add it
                            try mCore.addToConference(call: call)
                        }
                    }
                    print("Calls added to existing conference")
                } else {
                    // No active conference, so create a new conference
                    try mCore.enterConference()
                    print("Created a new conference and added calls")
                }
            } catch {
                print("Error merging calls: \(error.localizedDescription)")
            }
        }

        // Method to handle the merge call button press event
        func onMergeCallButtonPressed() {
            // Call the method to merge active calls
            mergeActiveCalls()
        }

    
   }


   

