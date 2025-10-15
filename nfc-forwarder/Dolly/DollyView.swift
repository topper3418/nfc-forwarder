//
//  Dolly.swift
//  nfc-forwarder
//
//  Created by Travis Opperud on 10/14/25.
//

import Foundation
import SwiftUI


struct DollyView: View {
    var dolly: Dolly
    
    var body: some View {
        VStack {
            
            Text("Scanned Dolly")
                .padding()
                .font(.title)
            
            Text(dolly.qrValue)
                .padding()
                .font(.title2)
            
            HStack {
                
                Text("Identifier:")
                Spacer()
                Text(dolly.identifier)
                    .padding()

            }
            
            HStack {
                
                Text("Type:")
                Spacer()
                Text(dolly.dollyType.string)
                    .padding()

            }
            
            HStack {
                
                Text("Dimensions:")
                Spacer()
                Text("\(dolly.length) x \(dolly.width)")
                    .padding()

            }
        }
        .padding()
        .border(.gray)
    }
}
