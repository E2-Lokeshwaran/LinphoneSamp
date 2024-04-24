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
    @IBOutlet weak var loginStatusLabel: UILabel!
    //UIview
    @IBOutlet weak var ViewOne: UIView!
    @IBOutlet weak var lbl: UILabel!
    
    //var registrationStateMessage: String?
    var callManager = CallManager()
    
    
    var registrationMessage: String?
    var isRegistrationStateHandled = false
    
    var shouldResetCallManager = false

    weak var registrationStateDelegate: RegistrationStateDelegate?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reset callManager if needed
            if shouldResetCallManager {
                callManager = CallManager()
                callManager.registrationStateDelegate = self
                shouldResetCallManager = false
            }

            isRegistrationStateHandled = false

            cleardata()
    }
    
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
        
        callManager.registrationStateDelegate = self
        
    }
    //Function to dismiss the keyboard when tapped outside of a text field
    @objc func dismissKeyboard()
    {
        //Call the endEditing method on the view to dismiss the keyboard
        view.endEditing(true)
    }
    
    //MARK: - Login Button
    @IBAction func loginButtonTapped(_ sender: UIButton)
    {
        isRegistrationStateHandled = false
        lbl.text = ""
        
        //logout
        if callManager.loggedIn
        {
            callManager.unregister()
            callManager.delete()
            shouldResetCallManager = true
            print("logout")
            return
        }
        else
        {
            // Check if all details are entered
            guard let username = usernameTextField.text,
                  !username.isEmpty,
                  let password = passwordTextField.text,
                  !password.isEmpty,
                  let domain = domainTextField.text,
                  !domain.isEmpty
            else
            {
                // Show an alert if any field is empty
                alert(message: "Please enter all details")
                return
            }
            // Attempt login
            //attemptLogin(username: username, password: password, domain: domain)
                        
            callManager.setUserCredentials(username: username, password: password, domain: domain)
            callManager.login()
        }
    }
    
    //MARK: - Segement controller
    
    @IBAction func transportSegmentedControlChanged(_ sender: UISegmentedControl)
    {
        let selectedTransport = sender.titleForSegment(at: sender.selectedSegmentIndex) ?? ""
        callManager.transportType = selectedTransport
    }
    //MARK: - Navigate to next page (SecondViewController)
    func navigateToNextPage()
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nextViewController = storyboard.instantiateViewController(withIdentifier: "SecondViewController") as? SecondViewController {
            nextViewController.receivedData = usernameTextField.text
            nextViewController.sipadd = domainTextField.text
            //staus label
            nextViewController.callManager = callManager
            nextViewController.registrationStateDelegate = self // Set the delegate
            navigationController?.pushViewController(nextViewController, animated: true)
            
            self.isRegistrationStateHandled = true
            
        }
    }
    
    //        func attemptLogin(username: String, password: String, domain: String)
    //        {
    //            UserDefaults.standard.set(username, forKey: "username")
    //            UserDefaults.standard.set(password, forKey: "password")
    //            UserDefaults.standard.set(domain, forKey: "domain")
    //            //Navigate to the next page
    //            navigateToNextPage()
    //        }
    //MARK: - Login Alert
    func alert(message: String)
    {
        let alert = UIAlertController(title: "Alert", message: "Check Details", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default,handler: nil))
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
    
    func registrationStateChanged(message: String, state: RegistrationState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lbl.text = message
            print("juneday", message)
            
            if !self.isRegistrationStateHandled 
            {
                if message == "Registration successful" 
                {
                    self.navigateToNextPage()
                    print("Mayday Registration successful")
                    self.isRegistrationStateHandled = true
                } 
                else if message == "Registration in progress"
                {
                    print("Mayday Registration in progress")
                }
                else if message == "io error"
                {
                    print("io error")
                    self.showAlert(message: "An I/O error occurred. Please check the credentials and try again.")
                    cleardata()
                    self.isRegistrationStateHandled = true
                }
                else if message == "Unauthorized"
                {
                    print("Mayday Unauthorized")
                    self.isRegistrationStateHandled = true
                    cleardata()
                }
                else
                {
                    self.showAlert(message: "Registration failed. Please check your credentials and try again.")
                    cleardata()
                    self.isRegistrationStateHandled = true
                }
            }
        }
    }
}
