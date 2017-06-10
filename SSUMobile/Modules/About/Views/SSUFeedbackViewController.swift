//
//  SSUFeedbackViewController.swift
//  SSUMobile
//
//  Created by Eric Amorde on 3/25/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation

class SSUFeedbackViewController: UITableViewController, UITextViewDelegate {
    
    @IBOutlet var textView: UITextView!
    @IBOutlet var emailTextField: UITextField!
    
    private var hasBegunEditing = false
    private var isSubmitting = false
    private var placeholderText: String?
    private var sendButton: UIBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(SSUFeedbackViewController.sendButtonPressed))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placeholderText = textView.text // set in storyboard
        
        navigationItem.rightBarButtonItem = sendButton
        sendButton.isEnabled = false
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if !hasBegunEditing {
            // The first time the user begins editing, clear the placeholder text.
            textView.text = ""
            hasBegunEditing = true
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        sendButton.isEnabled = !text.isEmpty
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            // If the user ended editing without entering text, put the placeholder back
            textView.text = placeholderText
        }
    }
    
    // MARK: Button actions
    
    @objc
    private func sendButtonPressed() {
        let content = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if !content.isEmpty {
            sendFeedbackSubmission(content: content, email: email)
        }
    }
    
    // MARK: Send submission
    
    /**
     Send feedback to moonlight
     
     - parameter content The text of the feedback/suggestion
     - parameter email The email of the user, or an empty string
     */
    private func sendFeedbackSubmission(content: String, email: String?) {
        if !SSUAboutModule.instance.canSubmitFeedback {
            alert(title: "Unable to submit feedback", message: "You recently submitted some feedback to us. Please wait a few minutes before sending another submission")
            return
        }
        isSubmitting = true
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let params: [String:Any] = [
            "os_name": "ios",
            "content": content,
            "email": email ?? "",
            "app_version": appVersion ?? "Unknown",
            "os_version": osVersion
        ]
        let hud = MBProgressHUD.showAdded(to: tableView, animated: true)
        SSUMoonlightCommunicator.postPath("ssumobile/feedback/", parameters: params) { (response, data, error) in
            if error != nil {
                self.alert(title: "Error", message: "There was an error when submitting your feedback. Please try again or come back later")
            } else {
                DispatchQueue.main.async {
                    hud.hide(animated: true)
                    SSUConfiguration.instance.lastFeedbackDate = Date()
                    self.alert(title: "Success", message: "Thank you for your feeedback!")
                    self.emailTextField.text = nil
                    self.textView.text = self.placeholderText ?? self.textView.text
                }
            }
        }
    }
    
    private func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
