//
//  ViewController.swift
//  TestIncoming
//
//  Created by Lokeshwaran on 01/04/24.
//

import UIKit
import linphonesw

class ViewController: UIViewController,RegistrationStateDelegate
{
    //User name
    @IBOutlet weak var usernameTextField: UITextField!
    //Password
    @IBOutlet weak var passwordTextField: UITextField!
    //Domain
    @IBOutlet weak var domainTextField: UITextField!
    //Segment controller
    @IBOutlet weak var transportSegmentedControl: UISegmentedControl!
    //Login Button
    @IBOutlet weak var loginButton: UIButton!
    //UIview
    @IBOutlet weak var ViewOne: UIView!
    //Login state State Label
    @IBOutlet weak var lbl: UILabel!
    //var registrationStateMessage: String?
    var callManager = CallManager()
    // Optional message about registration state.
    var registrationMessage: String?
    // Flag indicating if registration state is handled.
    var isRegistrationStateHandled = false
    // Flag indicating if the call manager should be reset.
    var shouldResetCallManager = false
    // Weak reference to a delegate for handling registration state.
    weak var registrationStateDelegate: RegistrationStateDelegate?
    
    //MARK: - ViewDidLoad
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Create a UITapGestureRecognizer instance named tap, specifying the target and action to be performed when the tap gesture is recognized.
        // When a tap gesture is recognized, it will call the dismissKeyboard method on the UIInputViewController instance represented by 'self'.
        // This effectively dismisses the keyboard when tapping outside of any input elements.
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        // Add the tap gesture recognizer to the view, enabling it to detect taps on the view and trigger the associated action.
        view.addGestureRecognizer(tap)
        //View corner radius
        ViewOne.layer.cornerRadius = 20
        // Set the view controller as the delegate for handling registration state in the call manager.
        callManager.registrationStateDelegate = self
        // Check if low power mode is enabled.
        checkLowPowerMode()
    }
    
    //MARK: - ViewWillAppear
    // Override function called when the view is about to appear on the screen.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reset callManager if needed
        // If the flag indicates a reset is needed, create a new instance of CallManager,
        // set the view controller as the registration state delegate, and reset the flag.
        if shouldResetCallManager
        {
            callManager = CallManager()
            callManager.registrationStateDelegate = self
            shouldResetCallManager = false
        }
        // Reset the flag indicating whether registration state is handled.
        isRegistrationStateHandled = false
        //Cleat any data in the view
        cleardata()
        //Check if low power mode is enabled
        checkLowPowerMode()
    }
    
    //MARK: - Login Button
    //left
    @IBAction func loginButtonTapped(_ sender: UIButton)
    {
        // Reset the flag indicating whether registration state is handled.
        isRegistrationStateHandled = false
        // Clear the status label.
        lbl.text = ""
        //logout if already logged in.
        if callManager.loggedIn
        {
            // Unregister and delete the call manager.
            callManager.unregister()
            callManager.delete()
            // Set flag to reset the call manager.
            shouldResetCallManager = true
            // Print logout message for debugging.
            print("logout")
            return
        }
        else
        {
            // Check if all details are entered
            guard let usernameText = usernameTextField.text,
                  let username = Int(usernameText),
                  username >= 4100 && username <= 4110,
                  let password = passwordTextField.text,
                  !password.isEmpty,
                  let domain = domainTextField.text,
                  !domain.isEmpty
            else {
                // Show an alert if any field is empty or username is out of range
                if let usernameText = usernameTextField.text, let username = Int(usernameText)
                {
                    if username < 4100 || username > 4110
                    {
                        showAlert(message: "Username should be between 4100 and 4110.")
                    }
                    else
                    {
                        alert(message: "Please enter all details")
                    }
                }
                return
            }
            // Set user credentials and attempt login.
            callManager.setUserCredentials(username: usernameText, password: password, domain: domain)
            callManager.login()
        }
    }
    
    //MARK: - Segement controller
    @IBAction func transportSegmentedControlChanged(_ sender: UISegmentedControl)
    {
        // Get the title of the selected segment or use an empty string if not found.
        let selectedTransport = sender.titleForSegment(at: sender.selectedSegmentIndex) ?? ""
        // Set the transport type in the call manager to the selected transport.
        callManager.transportType = selectedTransport
    }
    //MARK: - Navigate to next page (SecondViewController)
    func navigateToNextPage()
    {
        // Create a new instance of the Main storyboard.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        // Instantiate the view controller with the identifier "SecondViewController" from the storyboard.
        if let nextViewController = storyboard.instantiateViewController(withIdentifier: "SecondViewController") as? SecondViewController
        {
            // Pass data to the next view controller.
            nextViewController.receivedData = usernameTextField.text
            nextViewController.sipadd = domainTextField.text
            // Pass the call manager to the next view controller.
            nextViewController.callManager = callManager
            // Set the registration state delegate for the next view controller.
            nextViewController.registrationStateDelegate = self // Set the delegate
            // Push the next view controller onto the navigation stack.
            navigationController?.pushViewController(nextViewController, animated: true)
            // Set the flag indicating that registration state is handled.
            self.isRegistrationStateHandled = true
        }
    }
    
    //MARK: - Login Alert
    func alert(message: String)
    {
        // Create an alert controller with a fixed message and OK button.
        let alert = UIAlertController(title: "Alert", message: "Check Details", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default,handler: nil))
        // Present the alert controller modally.
        present(alert,animated: true,completion: nil)
    }
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func cleardata()
    {
        // Clear text fields
        usernameTextField.text = ""
        passwordTextField.text = ""
        domainTextField.text = ""
        // Reset segment control selection
        transportSegmentedControl.selectedSegmentIndex = -1
    }
    //MARK: - Registration state
    // Function called when the registration state changes.
    func registrationStateChanged(message: String, state: RegistrationState)
    {
        // Ensure UI updates are performed on the main thread.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Update the status label with the registration message.
            self.lbl.text = message
            // Check if the registration state has been handled.
            if !self.isRegistrationStateHandled
            {
                // Check if the registration state has been handled.
                if !self.isRegistrationStateHandled {
                    // Handle different registration states.
                    switch message {
                    case "Registration successful":
                        // If registration is successful, navigate to the next page.
                        self.navigateToNextPage()
                        print("Mayday Registration successful")
                        self.isRegistrationStateHandled = true
                    case "Registration in progress":
                        print("Mayday Registration in progress")
                    case "io error":
                        // If an I/O error occurs, show an alert and clear data.
                        print("Mayday I/O error")
                        self.showAlert(message: "An I/O error occurred. Please check the credentials and try again.")
                        self.cleardata()
                        self.isRegistrationStateHandled = true
                    case "Unauthorized":
                        // If unauthorized, clear data.
                        print("Mayday Unauthorized")
                        self.isRegistrationStateHandled = true
                        self.cleardata()
                    default:
                        // For any other registration failure, show an alert and clear data.
                        self.showAlert(message: "Registration failed. Please check your credentials and try again.")
                        self.cleardata()
                        self.isRegistrationStateHandled = true
                    }
                }
            }
        }
    }
        //MARK: - To CHECK and SHOW low power mode
        // Function to check if Low Power Mode is enabled.
        func checkLowPowerMode()
        {
            // Check if Low Power Mode is enabled.
            if ProcessInfo.processInfo.isLowPowerModeEnabled
            {
                // Print a message indicating Low Power Mode is enabled.
                print("Low Power Mode is enabled")
                // Show an alert on the main thread.
                DispatchQueue.main.async
                {
                    let alert = UIAlertController(title: "Low Power Mode", message: "Your device is in Low Power Mode. This may affect the app's performance and functionality.", preferredStyle: .alert)
                    // Add an OK action to the alert.
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    // Present the alert modally.
                    self.present(alert, animated: true, completion: nil)
                }
            }
            else
            {
                // Print a message indicating Low Power Mode is not enabled.
                print("Low Power Mode is not enabled")
            }
        }
        
        
    // Function to show a Low Power Mode alert with a delay.
    func showLowPowerModeAlert() {
        // Print a message indicating that the Low Power Mode alert is being shown.
        print("Showing Low Power Mode alert")
        
        // Create an alert controller to inform the user about Low Power Mode.
        let alertController = UIAlertController(title: "Low Power Mode", message: "Your device is in Low Power Mode. This may affect the app's performance and functionality.", preferredStyle: .alert)
        
        // Add an OK action to the alert.
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        // Present the alert modally.
        present(alertController, animated: true) {
            // Delay to keep the alert visible for a longer period.
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                alertController.dismiss(animated: true, completion: nil)
            }
        }
    }

        // Function to dismiss the keyboard when tapped outside of a text field.
        @objc func dismissKeyboard()
        {
            // Call the endEditing method on the view to dismiss the keyboard.
            // Passing true as the argument resigns the first responder status from any responder in the view's hierarchy.
            view.endEditing(true)
        }
}

