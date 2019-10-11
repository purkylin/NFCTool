//
//  NFCWriteViewController.swift
//  NFC
//
//  Created by Purkylin King on 2019/10/10.
//  Copyright © 2019 Purkylin King. All rights reserved.
//

import UIKit
import CoreNFC
import Combine

class NFCWriteViewController: UIViewController {
    @Published var inputText: String = ""
    
    let textField = UITextField()
    let button = createButton(title: "Write to tag")
    var session: NFCNDEFReaderSession?
    
    var cancelable: AnyCancellable?
    
    var message: NFCNDEFMessage? {
        guard let text = textField.text else { return nil }
        
        let record = NFCNDEFPayload.wellKnownTypeTextPayload(string: text, locale: Locale.current)!
        return NFCNDEFMessage(records: [record])
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Write"
        view.backgroundColor = UIColor.white
        
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.clearButtonMode = .whileEditing
        textField.placeholder = "Content"
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        button.addTarget(self, action: #selector(btnWriteClicked), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [textField, button])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 20
        
        view.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        
        cancelable = $inputText.map { $0.count > 0 }.sink { enabled in
            self.button.isEnabled = enabled
            self.button.alpha = enabled ? 1 : 0.6
        }
    }
    
    @objc func editingChanged(sender: UITextField) {
        inputText = sender.text ?? ""
    }
    
    @objc func btnWriteClicked() {
        print(textField.text ?? "")
        guard self.message != nil else { return }
        
        ready(write: true)
    }
    
    func ready(write: Bool = false) {
        let mode = write ? "write" : "read"
        
        guard NFCNDEFReaderSession.readingAvailable else {
            let alertController = UIAlertController(
                title: "Scanning Not Supported",
                message: "This device doesn't support tag scanning.",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
            present(alertController, animated: true, completion: nil)
            return
        }
        
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near an NDEF tag to \(mode) the message."
        session?.begin()
    }
    
    func showError(_ errorMessage: String) {
        let alertController = UIAlertController(
            title: "Session Invalidated",
            message: errorMessage,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension NFCWriteViewController: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError {
            if readerError.code == .readerSessionInvalidationErrorSystemIsBusy {
                showError("System busy")
            }
            print(readerError.localizedDescription)

        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("detected")
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            // Restart polling in 500 milliseconds.
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "More than 1 tag is detected. Please remove all tags and try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
        
        // Connect to the found tag and write an NDEF message to it.
        let tag = tags.first!
        session.connect(to: tag, completionHandler: { (error: Error?) in
            if nil != error {
                session.alertMessage = "Unable to connect to tag."
                session.invalidate()
                return
            }
            
            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                guard error == nil else {
                    session.alertMessage = "Unable to query the NDEF status of tag."
                    session.invalidate()
                    return
                }

                switch ndefStatus {
                case .notSupported:
                    session.alertMessage = "Tag is not NDEF compliant."
                    session.invalidate()
                case .readOnly:
                    session.alertMessage = "Tag is read only."
                    session.invalidate()
                case .readWrite:
                    tag.writeNDEF(self.message!, completionHandler: { (error: Error?) in
                        if nil != error {
                            session.alertMessage = "Write NDEF message fail: \(error!)"
                        } else {
                            session.alertMessage = "Write NDEF message successful."
                        }
                        session.invalidate()
                    })
                @unknown default:
                    session.alertMessage = "Unknown NDEF tag status."
                    session.invalidate()
                }
            })
        })
    }
    
    
}
