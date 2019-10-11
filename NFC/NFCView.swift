//
//  NFCView.swift
//  NFC
//
//  Created by Purkylin King on 2019/10/10.
//  Copyright © 2019 Purkylin King. All rights reserved.
//

import SwiftUI

struct NFCView: View {
    var body: some View {
        ContentViewController()
    }
}

struct ContentViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return NFCViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        //
    }
}

struct NFCView_Previews: PreviewProvider {
    static var previews: some View {
        NFCView()
    }
}
