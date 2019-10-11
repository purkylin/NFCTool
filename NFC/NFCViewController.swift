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
    
    var session: NFCReaderSession?
    
    let segmented = UISegmentedControl(items: ["NDEF", "Other"])

    var other: Bool {
        return segmented.selectedSegmentIndex == 1
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "NFC Tool"
        
        segmented.selectedSegmentIndex = 0
        
        let readBtn = createButton(title: "Read")
        readBtn.addTarget(self, action: #selector(btnReadClicked), for: .touchUpInside)
        view.addSubview(readBtn)

        
        let writeBtn = createButton(title: "Write")
        writeBtn.addTarget(self, action: #selector(btnWriteClicked), for: .touchUpInside)
        view.addSubview(writeBtn)
        
        let stackView = UIStackView(arrangedSubviews: [segmented, readBtn, writeBtn])
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
        
        if other {
            session = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693], delegate: self)
        } else {
            session = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: false)
        }
        
        session?.alertMessage = "Hold your iPhone near an tag to \(mode) the message."
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
    
    func showOtherResult(type: String, data: Data?) {
        let dismiss = { () in
            self.dismiss(animated: true, completion: nil)
        }
        
        let resultView = ScanOtherResultView(type: type, data: data, dismiss: dismiss)
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
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("active")
    }
    
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

extension NFCViewController: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("tag active")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError {
            if readerError.code == .readerSessionInvalidationErrorSystemIsBusy {
                showError("System busy")
            }
            print(readerError.localizedDescription)

        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        // https://swifting.io/blog/2019/07/11/53-first-steps-with-nfc-on-ios-13/
        
        print("ok tag")
        guard let tag = tags.first else { return }
        
        // 15693
        if case .iso15693(let nfc15693Tag) = tag {
            print("15693", nfc15693Tag)
            
            session.connect(to: tag) { error in
                if error != nil {
                    print(error!.localizedDescription)
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
                

                nfc15693Tag.readSingleBlock(requestFlags: [.highDataRate, .address], blockNumber: 0) { (data, error) in
                    if error != nil {
                        print(error!.localizedDescription)
                        session.invalidate(errorMessage: "Application failure")
                        return
                    }
                    
                    
                    DispatchQueue.main.async {
                        self.showOtherResult(type: "ISO15693", data: data)
                    }
                    
                    session.invalidate()
                }
            }
        }
        
        // mifare
        if case .miFare(let mifareTag) = tag {
            print("mifare", mifareTag)
            
            if mifareTag.mifareFamily == .ultralight {
                //
            } else if mifareTag.mifareFamily == .unknown {
                // 14443
            } else {
                // Do nothing
            }
            
            session.connect(to: tag) { error in
                if error != nil {
                    print(error!.localizedDescription)
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
                
                let apdu = NFCISO7816APDU(instructionClass: 0, instructionCode: 0xB0, p1Parameter: 0, p2Parameter: 0, data: Data(), expectedResponseLength: 16)
                
                mifareTag.sendMiFareISO7816Command(apdu) { (data, sw1, sw2, error) in
                    guard error != nil else {
                        print(error!.localizedDescription)
                        session.invalidate(errorMessage: "Application failure")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.showOtherResult(type: "Mifare", data: data)
                    }
                    
                    print("ok data", data)
                    session.invalidate()
                }
            }
        }
        
        // 7816
        if case .iso7816(let nfc7816Tag) = tag {
            print("7816", nfc7816Tag)
            
            session.connect(to: tag) { error in
                if error != nil {
                    print(error!.localizedDescription)
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
                
                let myAPDU = NFCISO7816APDU(instructionClass:0, instructionCode:0xB0, p1Parameter:0, p2Parameter:0, data: Data(), expectedResponseLength:16)
                nfc7816Tag.sendCommand(apdu: myAPDU) { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?)
                    in
                    
                    guard error != nil && !(sw1 == 0x90 && sw2 == 0) else {
                        session.invalidate(errorMessage: "Application failure")
                        return
                    }
                    
                    
                    DispatchQueue.main.async {
                        self.showOtherResult(type: "ISO7816", data: response)
                    }
                    
                    session.invalidate()
                }
            }
        }
    }
}
