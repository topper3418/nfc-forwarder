//
//  Dolly.swift
//  nfc-forwarder
//
//  Created by Travis Opperud on 10/14/25.
//

import Foundation


struct Dolly {
    let qrValue: String
    let dollyType: DollyType
    let length: Int
    let width: Int
    let prefix: String
    let identifier: String
    var writable: Bool = false
    
    init(scanInput: String) {
        print("initializing dolly from scan \(scanInput)")
        if scanInput.isEmpty {
            qrValue = "[NO SCAN]"
            dollyType = .none
            length = 0
            width = 0
            prefix = "[NO DATA]"
            identifier = "[NO ID]"
            return
        }
        qrValue = scanInput
        // Split on ":" to get dolly_id and code (code gets discarded)
        let components = qrValue.split(separator: ":")
        let dollyId = String(components[0])
        
        // Split dolly_id on "-" to get prefix, dims, typeid, identifier
        let idComponents = dollyId.split(separator: "-")
        if idComponents.count != 4 {  // return empty if unparseable
            print("Invalid dolly_id format: Expected three '-' separators")
            dollyType = .none
            length = 0
            width = 0
            prefix = "[INVALID SEGMENTS]"
            identifier = "[NONE]"
            return
        }
        let parsedPrefix = String(idComponents[0])
        let dims = String(idComponents[1])
        let parsedDollyTypeId = String(idComponents[2])
        let parsedIdentifier = String(idComponents[3])
        
        // Split dims on "X" to get length and width
        let dimComponents = dims.split(separator: "X")
        guard dimComponents.count == 2 else {
            print("Invalid dims format: Expected one 'X' separator")
            dollyType = .none
            length = 0
            width = 0
            prefix = "[INVALID SEGMENTS]"
            identifier = "[NONE]"
            return
        }
        let parsedLength = String(dimComponents[0])
        let parsedWidth = String(dimComponents[1])
        
        // assign the actual values
        // dolly type must be converted from string to int
        dollyType = .from(id: Int(parsedDollyTypeId) ?? 0) ?? .none
        length = Int(parsedLength) ?? 0
        width = Int(parsedWidth) ?? 0
        prefix = parsedPrefix
        identifier = parsedIdentifier
        writable = true
    }
    
    func payload(location: WriteLocation) -> Data? {
        if !writable { return nil }
        let tagLocationValue = UInt8(location.rawValue)
        let dollyTypeIdValue = UInt8(dollyType.integer)
        let lengthValue = UInt8(length)
        let widthValue = UInt8(width)
        let uints = [ // per the given specification
            tagLocationValue,
            dollyTypeIdValue,
            lengthValue,
            widthValue,
            0, 0, 0
        ]
        var data = Data(uints)
        let qrValueData = qrValue.data(using: .ascii, allowLossyConversion: false)!
        data.append(qrValueData)
        return data
    }
}


