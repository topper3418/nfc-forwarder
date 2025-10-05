import SwiftUI
import CoreNFC
import CodeScanner
internal import AVFoundation

struct ContentView: View {
    @State private var scannedText: String = ""
    @State private var isShowingScanner = false
    @State private var nfcStatus: String = "" // For feedback
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(scannedText.isEmpty ? " " : scannedText)
                .font(.body)
                .foregroundColor(.gray)
                .padding()
            
            if !nfcStatus.isEmpty {
                Text(nfcStatus)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
            
            Button(action: {
                isShowingScanner = true
            }) {
                Text("Scan QR Code")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.qr], completion: handleScan)
            }
            
            Button(action: {
                writeNFC()
            }) {
                Text("Write NFC Tag")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(scannedText.isEmpty)
        }
        .padding()
    }
    
    private func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let result):
            scannedText = result.string
        case .failure(let error):
            scannedText = "Scan failed: \(error.localizedDescription)"
        }
    }
    
    private func writeNFC() {
        guard NFCNDEFReaderSession.readingAvailable else {
            nfcStatus = "NFC not supported on this device."
            return
        }
        
        let session = NFCNDEFReaderSession(delegate: NFCTagWriter(scannedText: scannedText, statusUpdater: { status in
            self.nfcStatus = status
        }), queue: .main, invalidateAfterFirstRead: true) // true for single write
        session.alertMessage = "Hold your iPhone near an NFC tag to write."
        session.begin()
    }
}

// NFC Writing Delegate
class NFCTagWriter: NSObject, NFCNDEFReaderSessionDelegate {
    let textToWrite: String
    let statusUpdater: (String) -> Void
    
    init(scannedText: String, statusUpdater: @escaping (String) -> Void) {
        self.textToWrite = scannedText
        self.statusUpdater = statusUpdater
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Not used for writing
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            session.alertMessage = "Multiple tags detected. Remove extras and try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500)) {
                session.restartPolling()
            }
            return
        }
        
        guard let tag = tags.first else { return }
        
        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(errorMessage: "Connection failed: \(error.localizedDescription)")
                return
            }
            
            tag.queryNDEFStatus { status, capacity, error in
                if let error = error {
                    session.invalidate(errorMessage: "Status query failed: \(error.localizedDescription)")
                    return
                }
                
                guard status == .readWrite else {
                    session.invalidate(errorMessage: "Tag is not writable (status: \(status.rawValue)).")
                    return
                }
                
                let payload = NFCNDEFPayload.wellKnownTypeTextPayload(string: self.textToWrite, locale: .current)!
                let message = NFCNDEFMessage(records: [payload])
                
                tag.writeNDEF(message) { error in
                    if let error = error {
                        session.invalidate(errorMessage: "Write failed: \(error.localizedDescription)")
                    } else {
                        session.alertMessage = "Write successful!"
                        session.invalidate()
                    }
                }
            }
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        statusUpdater("Session invalidated: \(error.localizedDescription)")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
