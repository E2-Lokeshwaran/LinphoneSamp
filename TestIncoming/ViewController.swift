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
    // MARK: - Outlets
    
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

    
    // MARK: - View Controller Lifecycle
    
    var tutorialContext = CallManager()
    
    override func viewDidLoad() 
    {
        super.viewDidLoad()
        
       
            //keyboard invisible declare
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

        
        //View corner radius
        ViewOne.layer.cornerRadius = 20
        
        //UserDefaut
        if let savedUsername = UserDefaults.standard.string(forKey: "username"),
              let savedPassword = UserDefaults.standard.string(forKey: "password"),
              let savedDomain = UserDefaults.standard.string(forKey: "domain") 
        {
               // Configure your CallManager with the saved data
               callManager.username = savedUsername
               callManager.passwd = savedPassword
               callManager.domain = savedDomain
               
           }
    }
    
   

    
    // MARK: - IBActions
    
    //keyboard invisible func
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) 
    {
        //logout
        if tutorialContext.loggedIn
        {
            tutorialContext.unregister()
            tutorialContext.delete()
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
            
            tutorialContext.setUserCredentials(username: username, password: password, domain: domain)

            
            tutorialContext.login()
            
        }
    }
    
    func attemptLogin(username: String, password: String, domain: String) {
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(password, forKey: "password")
        UserDefaults.standard.set(domain, forKey: "domain")
        
        // Navigate to the next page
        navigateToNextPage()
    }

    
    //segment ctrl
    @IBAction func transportSegmentedControlChanged(_ sender: UISegmentedControl) {
        let selectedTransport = sender.titleForSegment(at: sender.selectedSegmentIndex) ?? ""
        tutorialContext.transportType = selectedTransport
    }
    

    //Navigate func
    func navigateToNextPage() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nextViewController = storyboard.instantiateViewController(withIdentifier: "SecondViewController") as? SecondViewController {
            nextViewController.receivedData = usernameTextField.text
            nextViewController.sipadd = domainTextField.text
            //staus label
            nextViewController.callManager = tutorialContext
            navigationController?.pushViewController(nextViewController, animated: true)
            
//            let secondViewController = SecondViewController()
//            secondViewController.callManager = callMan
            
        }
    }
    
    
    //Alert func
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

