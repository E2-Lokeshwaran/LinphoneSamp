//
//  ViewController.swift
//  TestIncoming
//
//  Created by Lokeshwaran on 01/04/24.
//

import UIKit
import linphonesw

class ViewController: UIViewController
{
    
    var registrationStateMessage: String?
    var callManager = CallManager()
    
    
    //Login
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var domainTextField: UITextField!
    

    //Login segment & button
    @IBOutlet weak var transportSegmentedControl: UISegmentedControl!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginStatusLabel: UILabel!
    
    
    //UIview
    @IBOutlet weak var ViewOne: UIView!
    

    @IBOutlet weak var lbl: UILabel!

        
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
        
    }
    
    
    // MARK: - IBActions
    
    //keyboard invisible
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) 
    {
        //logout
        if callManager.loggedIn
        {
            callManager.unregister()
            callManager.delete()
            print("logout")
        }

        else {
            // Check if all details are entered
            guard let username = usernameTextField.text,
                  !username.isEmpty,
                  let password = passwordTextField.text,
                  !password.isEmpty,
                  let domain = domainTextField.text,
                  !domain.isEmpty else {
                // Show an alert if any field is empty
                alert(message: "Please enter all details")
                return
            }

            // Attempt login
            attemptLogin(username: username, password: password, domain: domain)
            callManager.setUserCredentials(username: username, password: password, domain: domain)
    
            callManager.login()
        }
    }
    
   

    //MARK: - Segent ctrl
    
    @IBAction func transportSegmentedControlChanged(_ sender: UISegmentedControl) {
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
    
    func attemptLogin(username: String, password: String, domain: String)
    {
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(password, forKey: "password")
        UserDefaults.standard.set(domain, forKey: "domain")
        
        // Navigate to the next page
        navigateToNextPage()
    }
    
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
        
}

