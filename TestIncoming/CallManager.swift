//
//  CallManager.swift
//  TestIncoming
//
//  Created by Lokeshwaran on 01/04/24.
//


import linphonesw
import AVFoundation


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
    var isVideoEnabled: Bool = false
    var canChangeCamera: Bool = false
    
    var remoteAddress: String = ""

    
    //Incoming call related variables
    var isCallIncoming: Bool = false
    var isSpeakerEnabled: Bool = false
    var isMicrophoneEnabled: Bool = false
    var incomingCallMsg: String = ""
    var incomingRemoteAddress: String = "Nobody yet"
    

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
        do {
            if (mCore.callsNb == 0) { return }
            if let call = mCore.currentCall {
                let params = try mCore.createCallParams(call: call)
                params.videoEnabled = !(call.currentParams!.videoEnabled)
                try call.update(params: params)
            }
        } catch { print(error.localizedDescription) }
    }
    
    
    //Switch camera
    func toggleCamera()
    {
        do {
            let currentDevice = mCore.videoDevice
            for camera in mCore.videoDevicesList {
                if (camera != currentDevice && camera != "StaticImage: Static picture") {
                    try mCore.setVideodevice(newValue: camera)
                    break
                }
            }
        } catch { print(error.localizedDescription) }
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
     

}
