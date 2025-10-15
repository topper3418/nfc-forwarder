/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller that scans and displays NDEF messages.
*/

import UIKit
import CoreNFC

/// - Tag: MessagesTableViewController
class NFCReaderService: NSObject, NFCNDEFReaderSessionDelegate {

    // MARK: - Properties

    let reuseIdentifier = "reuseIdentifier"
    var session: NFCNDEFReaderSession?
    var alertSetter: ((_ title: String, _ message: String?) -> Void)?
    var displayReadResults: ((NFCNDEFMessage) -> Void)?
    
    init(
        alertSetter: ((String, String?) -> Void)? = nil,
        displayReadResults: ((NFCNDEFMessage) -> Void)? = nil,
    ) {
        self.alertSetter = alertSetter
        self.displayReadResults = displayReadResults
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
        session?.alertMessage = "Hold your iPhone near the item to learn more about it."
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
        print("Did detect NDEF Tags")
        if tags.count > 1 {
            // Restart polling in 500ms
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            print("More than one tag detected")
            session.alertMessage = "More than 1 tag is detected, please remove all tags and try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
        
        // Connect to the found tag and perform NDEF message reading
        let tag = tags.first!
        print("Extracting one tag")
        session.connect(to: tag, completionHandler: { (error: Error?) in
            if nil != error {
                print("Error connecting to tag")
                session.alertMessage = "Unable to connect to tag."
                session.invalidate()
                self.alertSetter?("Error connecting to tag", error?.localizedDescription ?? "")
                return
            }
            
            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                if .notSupported == ndefStatus {
                    print("Tag not NDEF compliant")
                    session.alertMessage = "Tag is not NDEF compliant"
                    session.invalidate()
                    self.alertSetter?("Tag is not NDEF compliant", nil)
                    return
                } else if nil != error {
                    print("Error querying tag")
                    session.alertMessage = "Unable to query NDEF status of tag"
                    session.invalidate()
                    self.alertSetter?("Unable to query NDEF status of tag", nil)
                    return
                }
                print("got to the reading part")
                
                tag.readNDEF(completionHandler: { (message: NFCNDEFMessage?, error: Error?) in
                    print("got to the completion handler")
                    var statusMessage: String
                    if nil != error || nil == message {
                        statusMessage = "Fail to read NDEF from tag"
                    } else {
                        statusMessage = "Found 1 NDEF message"
                        if let message = message {
                            self.displayReadResults?(message)
                        }
                    }
                    
                    session.alertMessage = statusMessage
                    session.invalidate()
                })
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
