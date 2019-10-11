//
//  ScanOtherResultView.swift
//  NFC
//
//  Created by Purkylin King on 2019/10/11.
//  Copyright © 2019 Purkylin King. All rights reserved.
//

import Foundation
import SwiftUI

struct ScanOtherResultView: View {
    let type: String
    let data: Data?
    let dismiss: (() -> Void)?
    
    init(type: String, data: Data?, dismiss: (() -> Void)?) {
        self.type = type
        self.data = data
        self.dismiss = dismiss
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                Button(action: {
                    self.dismiss?()
                }) {
                    Text("Close")
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44, maxHeight: 44, alignment: .leading)
            .padding(.horizontal, 12)
            .background(Color("form"))
            
            Text(type).padding(.top, 40).padding(.horizontal, 12).font(.title)
            
            Form {
                Section(header: Text("RECORD")) {
                    if data != nil {
                        Text("Binary")
                    }
                }
            }
        }.background(Color("form"))
        

    }
}
