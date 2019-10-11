//
//  ScanResultView.swift
//  NFC
//
//  Created by Purkylin King on 2019/10/10.
//  Copyright © 2019 Purkylin King. All rights reserved.
//

import SwiftUI
import CoreNFC

struct ScanResultView: View {
    let record: NFCNDEFPayload?
    let dismiss: (() -> Void)?
    
    init(record: NFCNDEFPayload?, dismiss: (() -> Void)?) {
        self.record = record
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
            
            Text(record?.typeNameFormat.typeName ?? "").padding(.top, 40).padding(.horizontal, 12).font(.title)
            
            Form {
                Section(header: Text("RECORD")) {
                    if record?.body != nil {
                        Text(record!.body!)
                    }
                }
            }
        }.background(Color("form"))
        

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

struct ScanResultView_Previews: PreviewProvider {
    static var previews: some View {
        ScanResultView(record: nil, dismiss: nil)
    }
}

extension NFCTypeNameFormat {
    var typeName: String {
        switch self {
        case .absoluteURI:
            return "URI"
        case .empty:
            return "Empty"
        case .media:
            return "Media"
        case .nfcExternal:
            return "NFC External"
        case .nfcWellKnown:
            return "NFC Wellknown"
        case .unchanged:
            return "Unchanged"
        case .unknown:
            return "Unknown"
        @unknown default:
            fatalError()
        }
    }
}

extension NFCNDEFPayload {
    var body: String? {
        switch self.typeNameFormat {
        case .nfcWellKnown:
            let (info, _) = self.wellKnownTypeTextPayload()
            return info
        case .absoluteURI:
            let url = self.wellKnownTypeURIPayload()
            return url?.absoluteString
        default:
            return nil
        }
    }
}
