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

    
    @IBOutlet weak var AfterRegister: UIButton!
    
    //var registrationStateMessage: String?
    var callManager = CallManager()
    
    weak var registrationStateDelegate: RegistrationStateDelegate?
    
        
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
        
//        if lbl.text == "Registration successful"
//        {
//            AfterRegister.isHidden = false
//        }
//        else
//        {
//            AfterRegister.isHidden = true
//        }

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
        //logout
        if callManager.loggedIn
        {
            callManager.unregister()
            callManager.delete()
            print("logout")
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
            
            //callManager.login()
            
            // Login and navigate to next page only if registration status is "OK"
            callManager.login { [weak self] success in
//                        if success {
//                            // Check registration status
//                            if self?.callManager.loggedIn ?? false {
//                                // Navigate to next page
//                                self?.navigateToNextPage()
//                            } else {
//                                // Show error message if login fails
//                                self?.showAlert(message: "1Login failed. Please check your credentials.")
//                            }
//                        } else {
//                            // Show error message if login fails
//                            self?.showAlert(message: "2Login failed. Please check your credentials.")
//                        }
                    }
            
            
         
        }
    }
        
    //MARK: - Segent ctrl
    
    @IBAction func transportSegmentedControlChanged(_ sender: UISegmentedControl)
    {
        let selectedTransport = sender.titleForSegment(at: sender.selectedSegmentIndex) ?? ""
        callManager.transportType = selectedTransport
    }
    //MARK: - Navigate to next page (SecondViewController)
    func navigateToNextPage() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nextViewController = storyboard.instantiateViewController(withIdentifier: "SecondViewController") as? SecondViewController {
            nextViewController.receivedData = usernameTextField.text
            nextViewController.sipadd = domainTextField.text
            //staus label
            nextViewController.callManager = callManager
            navigationController?.pushViewController(nextViewController, animated: true)
        }
    }
//    func attemptLogin(username: String, password: String, domain: String)
//    {
//        UserDefaults.standard.set(username, forKey: "username")
//        UserDefaults.standard.set(password, forKey: "password")
//        UserDefaults.standard.set(domain, forKey: "domain")
//        // Navigate to the next page
//        navigateToNextPage()
//    }
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
    
    func registrationStateChanged(message: String, state: RegistrationState)
    {
        registrationStateDelegate?.registrationStateChanged(message: message, state: state)

        DispatchQueue.main.async { [weak self] in
            self?.lbl.text = message
            
            //self?.lbl.text = "Status: \(state), Message: \(message)"
        }
//        // Check if registration is successful
//                if message.contains("Registration successful") {
//                    // Navigate to next page
//                    self.navigateToNextPage()
//                }
//        else
//        {
//                    // Show alert message
//                    self.showAlert(message: "Registration failed. Please try again.")
//                }
        print("LokeshE2 \(message), state: \(state)")

    }
    
    
    @IBAction func AfterRegister(_ sender: UIButton)
    {
        if lbl.text == "Registration successful"
        {
            print("mypc ok")
            navigateToNextPage()
        }
        else
        {
            print("mypc no ok")
        }
    }
    
    

}

