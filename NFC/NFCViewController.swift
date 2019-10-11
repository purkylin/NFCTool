//
//  NFCViewController.swift
//  NFC
//
//  Created by Purkylin King on 2019/10/10.
//  Copyright © 2019 Purkylin King. All rights reserved.
//

import UIKit
import CoreNFC
import SwiftUI

class NFCViewController: UIViewController {
    
    var session: NFCNDEFReaderSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "NFC Tool"
        
        let readBtn = createButton(title: "Read")
        readBtn.addTarget(self, action: #selector(btnReadClicked), for: .touchUpInside)
        view.addSubview(readBtn)

        
        let writeBtn = createButton(title: "Write")
        writeBtn.addTarget(self, action: #selector(btnWriteClicked), for: .touchUpInside)
        view.addSubview(writeBtn)
        
        let stackView = UIStackView(arrangedSubviews: [readBtn, writeBtn])
        stackView.spacing = 20
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true
        
        view.backgroundColor = .white
        
        let leftItem = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(btnInfoClicked))
        self.navigationItem.leftBarButtonItem = leftItem
    }
    
    @objc func btnInfoClicked() {
        // TODO
//        let titleLabel = UILabel()
//        titleLabel.text = "NFC Tool"
//
//        let versionLabel = UILabel()
//        versionLabel.text = "1.0.0(10)"
//
//
//        let stackView = UIStackView(arrangedSubviews: [titleLabel, versionLabel])
//        stackView.axis = .vertical
//        stackView.alignment = .center
//
//
//        UIView.transition(with: stackView, duration: 3.0, options: .curveEaseIn, animations: nil, completion: nil)
        
        
    }
    
    @objc func btnReadClicked() {
        print("read")
        ready(write: false)
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
        
        session = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near an NDEF tag to \(mode) the message."
        session?.begin()
    }
    
    @objc func btnWriteClicked() {
        print("write")
        let vc = NFCWriteViewController()
        self.navigationController?.pushViewController(vc, animated: true)
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
    
    func showResult(record: NFCNDEFPayload) {
        let dismiss = { () in
            self.dismiss(animated: true, completion: nil)
        }
        
        let resultView = ScanResultView(record: record, dismiss: dismiss)
        let vc = UIHostingController(rootView: resultView)
        
        self.showDetailViewController(vc, sender: nil)
    }
    
    deinit {
        if let session = session {
            if session.isReady {
                session.invalidate()
            }
        }
    }
    
    func output(record: NFCNDEFPayload) {
        switch record.typeNameFormat {
        case .empty:
            return
        case .absoluteURI:
            if let url = record.wellKnownTypeURIPayload() {
                print(url)
            }
        case .nfcWellKnown:
            let (info, _) = record.wellKnownTypeTextPayload()
            if let info = info {
                print(info)
            }
        case .unknown:
            print("Unknown data")
        default:
            print("other")
        }
    }
}

extension NFCViewController: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError {
            if readerError.code == .readerSessionInvalidationErrorSystemIsBusy {
                showError("System busy")
            }
            print(readerError.localizedDescription)

        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        //
        if let message = messages.first {
            if let record = message.records.first {
                output(record: record)
                session.invalidate()
                showResult(record: record)

            }
        }
    }
}
