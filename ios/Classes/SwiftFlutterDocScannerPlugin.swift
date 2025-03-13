import Flutter
import UIKit
import Vision
import VisionKit
import PDFKit

@available(iOS 13.0, *)
public class SwiftFlutterDocScannerPlugin: NSObject, FlutterPlugin, VNDocumentCameraViewControllerDelegate {
   var resultChannel: FlutterResult?
   var presentingController: VNDocumentCameraViewController?
   var currentMethod: String?

   public static func register(with registrar: FlutterPluginRegistrar) {
       let channel = FlutterMethodChannel(name: "flutter_doc_scanner", binaryMessenger: registrar.messenger())
       let instance = SwiftFlutterDocScannerPlugin()
       registrar.addMethodCallDelegate(instance, channel: channel)
   }

   public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
       if call.method == "getScanDocuments" || call.method == "getScannedDocumentAsImages" || call.method == "getScannedDocumentAsPdf" {
           let presentedVC: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
           self.resultChannel = result
           self.currentMethod = call.method
           self.presentingController = VNDocumentCameraViewController()
           self.presentingController!.delegate = self
           presentedVC?.present(self.presentingController!, animated: true)
       } else {
           result(FlutterMethodNotImplemented)
       }
   }

   func getDocumentsDirectory() -> URL {
       return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
   }

   public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
       guard scan.pageCount > 0 else {
           resultChannel?(FlutterError(code: "NO_PAGES", message: "No pages were scanned", details: nil))
           presentingController?.dismiss(animated: true)
           return
       }
       
       if currentMethod == "getScanDocuments" || currentMethod == "getScannedDocumentAsImages" {
           saveScannedImage(scan: scan)
       } else if currentMethod == "getScannedDocumentAsPdf" {
           saveScannedPdf(scan: scan)
       }
       presentingController?.dismiss(animated: true)
   }

   private func saveScannedImage(scan: VNDocumentCameraScan) {
       let tempDirPath = getDocumentsDirectory()
       let df = DateFormatter()
       df.dateFormat = "yyyyMMdd-HHmmss"
       let formattedDate = df.string(from: Date())
       
       let page = scan.imageOfPage(at: 0)  // Restrict to first page only
       let url = tempDirPath.appendingPathComponent(formattedDate + "-0.png")
       try? page.pngData()?.write(to: url)
       resultChannel?([url.path])
   }

   private func saveScannedPdf(scan: VNDocumentCameraScan) {
       let tempDirPath = getDocumentsDirectory()
       let df = DateFormatter()
       df.dateFormat = "yyyyMMdd-HHmmss"
       let formattedDate = df.string(from: Date())
       let pdfFilePath = tempDirPath.appendingPathComponent("\(formattedDate).pdf")

       let pdfDocument = PDFDocument()
       let pageImage = scan.imageOfPage(at: 0)  // Restrict to first page only
       if let pdfPage = PDFPage(image: pageImage) {
           pdfDocument.insert(pdfPage, at: 0)
       }

       do {
           try pdfDocument.write(to: pdfFilePath)
           resultChannel?(pdfFilePath.path)
       } catch {
           resultChannel?(FlutterError(code: "PDF_CREATION_ERROR", message: "Failed to create PDF", details: error.localizedDescription))
       }
   }

   public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
       resultChannel?(nil)
       presentingController?.dismiss(animated: true)
   }

   public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
       resultChannel?(FlutterError(code: "SCAN_ERROR", message: "Failed to scan document", details: error.localizedDescription))
       presentingController?.dismiss(animated: true)
   }
}



// import Flutter
// import UIKit
// import Vision
// import VisionKit
//
// @available(iOS 13.0, *)
// public class SwiftFlutterDocScannerPlugin: NSObject, FlutterPlugin, VNDocumentCameraViewControllerDelegate {
//    var resultChannel :FlutterResult?
//    var presentingController: VNDocumentCameraViewController?
//
//   public static func register(with registrar: FlutterPluginRegistrar) {
//     let channel = FlutterMethodChannel(name: "flutter_doc_scanner", binaryMessenger: registrar.messenger())
//     let instance = SwiftFlutterDocScannerPlugin()
//     registrar.addMethodCallDelegate(instance, channel: channel)
//   }
//
//   public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
//     if call.method == "getScanDocuments" {
//             let presentedVC: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
//             self.resultChannel = result
//             self.presentingController = VNDocumentCameraViewController()
//             self.presentingController!.delegate = self
//             presentedVC?.present(self.presentingController!, animated: true)
//            } else {
//             result(FlutterMethodNotImplemented)
//             return
//        }
//   }
//
//
//     func getDocumentsDirectory() -> URL {
//         let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//         let documentsDirectory = paths[0]
//         return documentsDirectory
//     }
//
//     public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
//         let tempDirPath = self.getDocumentsDirectory()
//         let currentDateTime = Date()
//         let df = DateFormatter()
//         df.dateFormat = "yyyyMMdd-HHmmss"
//         let formattedDate = df.string(from: currentDateTime)
//         var filenames: [String] = []
//         for i in 0 ... scan.pageCount - 1 {
//             let page = scan.imageOfPage(at: i)
//             let url = tempDirPath.appendingPathComponent(formattedDate + "-\(i).png")
//             try? page.pngData()?.write(to: url)
//             filenames.append(url.path)
//         }
//         resultChannel?(filenames)
//         presentingController?.dismiss(animated: true)
//     }
//
//     public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
//         resultChannel?(nil)
//         presentingController?.dismiss(animated: true)
//     }
//
//     public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
//         resultChannel?(nil)
//         presentingController?.dismiss(animated: true)
//     }
// }
