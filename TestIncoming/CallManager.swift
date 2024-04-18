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
    
    //Registration sate
    weak var registrationStateDelegate: RegistrationStateDelegate?
    
    weak var SecondVc : SecondViewController?
    weak var delegate: CallManagerDelegate?
    weak var vc : ViewController?
    
    //call state
    var callStateDidChange: ((Call.State) -> Void)?
    
    //for speaker toggle
    let audioSession = AVAudioSession.sharedInstance()
    
    
    var mCore: Core!
    var call: Call?
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
    var isVideoEnabled: Bool = false
    
    //Property to store call duration
    var callDuration: TimeInterval = 0
    
    //Method to update the call duration
    func updateCallDuration(duration: TimeInterval)
    {
        callDuration = duration
    }
    
    
    //Method to retrieve the call duration
    func getCallDuration() -> TimeInterval
    {
        return callDuration
    }
    

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
                    print("CallDuration", call.duration)

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
    //MARK: - Login
    func login(completion: @escaping (Bool) -> Void)
    {
        mCoreDelegate = CoreDelegateStub(onAccountRegistrationStateChanged: { [weak self] (core: Core, account: Account, state: RegistrationState, message: String) in
            // Print the registration state and associated message
            
            print("Registration state lok: \(state), Message: \(message)")
            self?.loggedIn = (state == .Ok)
            
            self?.registrationStateDelegate?.registrationStateChanged(message: message, state: state)
            //To print the status and the message of the log in user.
            let bcd = message
            let xyz = state
            print("msg--->",bcd)
            print("stss--->",xyz)
            
            
            // Call the completion handler with the login success status
            completion(state == .Ok)

            
        })
        mCore.addDelegate(delegate: mCoreDelegate)
        
        //User selecting the type of security layer.
        do {
            //selection transport layer
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
    //MARK: - Unregister user
    
    func unregister()
    {
        // Check if there is a non-nil value assigned to the variable mCore.defaultAccount.
        if let account = mCore.defaultAccount
        {
            // Assign the value of account.params to a new constant named params.
            let params = account.params
            // Clone the params object if it's not nil and assign the cloned object to clonedParams.
            let clonedParams = params?.clone()
            // If clonedParams is not nil, set its registerEnabled property to false.
            clonedParams?.registerEnabled = false
            // Update the params property of the account with the clonedParams object.
            account.params = clonedParams
        }
    }
    
    //MARK: - Delete user

    func delete()
    {
        if let account = mCore.defaultAccount
        {
            // Remove the specified account from the mCore.
            mCore.removeAccount(account: account)
            //Clear all accouts from mCore
            mCore.clearAccounts()
            //Clear all authentication information from the mCore
            mCore.clearAllAuthInfo()
        }
    }
    //MARK: - Outgoing call
    
    func outgoingCall()
    {
        do
        {
            // Create a remote address using Factory.Instance.createAddress, and assign it to the constant remoteAddress. The remoteAddress is obtained from a variable named remoteAddress, presumably defined elsewhere.
            let remoteAddress = try Factory.Instance.createAddress(addr: remoteAddress)
            // Create call parameters using mCore.createCallParams with a nil call argument, and assign them to the constant params.
            let params = try mCore.createCallParams(call: nil)
            // Set the mediaEncryption property of the params object to MediaEncryption.None.
            params.mediaEncryption = MediaEncryption.None
            // Initiate an outgoing call using mCore.inviteAddressWithParams with the remoteAddress and params objects.
            let _ = mCore.inviteAddressWithParams(addr: remoteAddress, params: params)
        }
        catch
        {
            // Print the localized description of the error.
            print(error.localizedDescription)
        }
    }
    //MARK: - Terminate call
    
    func terminateCall()
    {
        do
        {
            // Check if there are no active calls in mCore.
            if (mCore.callsNb == 0)
            {
                // Exit the function early if there are no active calls.
                return
            }
            // Attempt to terminate the current call using mCore.currentCall?.terminate(). If there is no current call, this line does nothing.
            try mCore.currentCall?.terminate()
        }
        catch
        {
            // Print the localized description of the error.
            print(error.localizedDescription)
        }
    }
    //MARK: - Accept call
    
    func acceptCall()
    {
        do {
            // Attempt to accept the current call using mCore.currentCall?.accept(). If there is no current call, this line does nothing.
            try mCore.currentCall?.accept()
        }
        catch
        { 
            // Log the localized description of the error using NSLog.
            NSLog(error.localizedDescription)
        }
    }
    
    //MARK: - Mute & Unmute
    
    func muteMicrophone()
    {
        // The following toggles the microphone, disabling completely / enabling the sound capture
        // from the device microphone
        mCore.micEnabled = !mCore.micEnabled
        isMicrophoneEnabled = !isMicrophoneEnabled
    }
    
    //MARK: - Toggle video (on or off video)
    
    func toggleVideo()
    {
        
        do {
            // Check if there's an ongoing call
            guard let call = mCore.currentCall 
            else
            {
                print("No ongoing call")
                return
            }
            
            // Create call parameters
            let params = try mCore.createCallParams(call: call)
            
            // Toggle video status
            params.videoEnabled = !call.currentParams!.videoEnabled
            
            // Update call parameters
            try call.update(params: params)
        } 
        catch
        {
            print("Error toggling video: \(error.localizedDescription)")
        }
        
        if isVideoEnabled
        {
            isVideoEnabled = false
        }
        
        else
        {
            isVideoEnabled = true
        }
    }
    
    //MARK: - Switch camera (front or back camera)
     
    func toggleCamera()
    {
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
    
    //MARK: - Pause or resume
    
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
        } 
        catch
        {
            print(error.localizedDescription)
        }
    }
    
    //MARK: - Toggle Speaker
    
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

}




   

