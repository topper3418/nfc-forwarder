import SwiftUI
import CoreNFC 
import CodeScanner
import AVFoundation


struct AlertContent {
    let title: String
    let message: String
}

struct MainView: View {
    
    // MARK: Properties
    
    // scanning results
    @State private var nfcScanResult: String = ""
    @State private var qrScanResult: String = ""
    @State private var dolly: Dolly = Dolly(scanInput: "")
    // view state
    @State private var isNFCScanning: Bool = false
    @State private var isQrScanning: Bool = false
    @State private var alertContent: AlertContent?
    @State private var writingTo: WriteLocation? = nil
    // nfc services
    @State private var session: NFCNDEFReaderSession?
    @State private var nfcReaderService: NFCReaderService? = nil
    @State private var nfcWriterService: NFCWriterService? = nil
    // helper
    private func alertSetter(title: String, message: String?) {
        alertContent = AlertContent(title: title, message: message ?? "")
    }
    
    // - MARK: Initializer
    
    private func initServices() {
        // Initialize scanningService with closures
        nfcReaderService = NFCReaderService(
            alertSetter: self.alertSetter,
            displayReadResults: {message in
                print("Displaying message")
                let record = message.records.first!
                let payload = String(data: record.payload, encoding: .utf8)
                nfcScanResult = payload ?? "No data found!"
            }
        )
        nfcWriterService = NFCWriterService(
            alertSetter: self.alertSetter,
            getMessage: {
                let data = dolly.payload(location: writingTo!)
                if let data = data {
                    let payload = NFCNDEFPayload(
                        format: .nfcWellKnown,
                        type: "T".data(using: .ascii)!,
                        identifier: Data(),
                        payload: data
                    )
                    return NFCNDEFMessage(records: [payload])
                } else {
                    return NFCNDEFMessage(records: [])
                }
            }
        )
    }
    
    // - MARK: Scan Handler
    
    private func handleScan(result: Result<ScanResult, ScanError>) {
        isQrScanning = false
        switch result {
        case .success(let result):
            qrScanResult = result.string
            dolly = Dolly(scanInput: result.string)
            print("Scanned and populated dolly: \(dolly)")
        case .failure(let error):
            qrScanResult = "Scan failed: \(error.localizedDescription)"
            dolly = Dolly(scanInput: "")
        }
    }

    
    // MARK: Structure
    
    var body: some View {
        VStack(alignment: .center) {
            
            Text("NFC Forwarder")
                .padding()
                .font(.largeTitle)
            
            DollyView(dolly: dolly)
            
            Text(nfcScanResult)
                .padding()
                .foregroundColor(.gray)
            
            Spacer()
            
            Button("QR Scan") {
                print("Starting QR scan...")
                isQrScanning = true
            }                    .font(.headline)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .sheet(isPresented: $isQrScanning) {
                CodeScannerView(codeTypes: [.qr], completion: handleScan)
            }

            Button("NFC Scan") {
                print("Starting NFC scan...")
                nfcReaderService?.startNFCSession()
            }
            .font(.headline)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Button("Hitch Write") {
                print("Starting NFC hitch write...")
                writingTo = .hitch
                nfcWriterService?.startNFCSession()
            }
            .font(.headline)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("Handlebar Write") {
                print("Starting NFC handlebar write...")
                writingTo = .handlebar
                nfcWriterService?.startNFCSession()
            }
            .font(.headline)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("Clear", role: .destructive) {
                print("Clearing Scan")
                dolly = Dolly(scanInput: "")
            }
            .font(.headline)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .alert(isPresented: Binding<Bool>(
            get: { alertContent != nil },
            set: { if !$0 { alertContent = nil } }
        )) {
            Alert(
                title: Text(alertContent?.title ?? ""),
                message: Text(alertContent?.message ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            initServices()
        }
    }
}


#Preview {
    MainView()
}
