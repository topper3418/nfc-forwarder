/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller that scans and displays NDEF messages.
*/

import UIKit
import CoreNFC

/// - Tag: MessagesTableViewController
class NFCWriterService: NSObject, NFCNDEFReaderSessionDelegate {

    // MARK: - Properties

    let reuseIdentifier = "reuseIdentifier"
    var session: NFCNDEFReaderSession?
    var alertSetter: ((_ title: String, _ message: String?) -> Void)?
    var displayWriteResults: ((NFCNDEFMessage) -> Void)?
    var message: NFCNDEFMessage = NFCNDEFMessage(records: [])
    var getMessage: (() -> NFCNDEFMessage) = { NFCNDEFMessage(records: []) }

    init(
        alertSetter: ((String, String?) -> Void)? = nil,
        getMessage: @escaping (() -> NFCNDEFMessage)
    ) {
        self.alertSetter = alertSetter
        self.getMessage = getMessage
        super.init()
    }
    
    // MARK: - Actions
    
    // Start NFC session to read tags
    func startNFCSession() {
        print("Reader session button pressed")
        // Check if the device supports NFC
        guard NFCNDEFReaderSession.readingAvailable else {
            let errorMessage = "NFC not available on this device"
            print(errorMessage)
            alertSetter?("Permissions Issue", errorMessage)
            return
        }
        
        print("Setting up scanning session")

        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near the item to write to it."
        print("Starting scanning session")
        session?.begin()
    }

    // MARK: - NFCNDEFReaderSessionDelegate

    /// - Tag: processingTagData
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("Did detect NDEFs")
    }

    /// - Tag: processingNDEFTag
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
                    let message = self.getMessage()
                    tag.writeNDEF(message, completionHandler: { (error: Error?) in
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

    /// - Tag: sessionBecomeActive
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        
    }
    
    /// - Tag: endScanning
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Check the invalidation reason from the returned error.
        if let readerError = error as? NFCReaderError {
            // Show an alert when the invalidation reason is not because of a
            // successful read during a single-tag read session, or because the
            // user canceled a multiple-tag read session from the UI or
            // programmatically using the invalidate method call.
            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                let title = "Session Invalidated"
                let message = error.localizedDescription
                print("\(title): \(message)")
                alertSetter?(title, message)
            }
        }

        // To read new tags, a new session instance is required.
        self.session = nil
    }
}
