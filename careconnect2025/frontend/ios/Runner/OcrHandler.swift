import Foundation
import Vision
import UIKit
import Flutter

final class OcrHandler {
    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: "care_connect/ocr", binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "recognizeText":
                guard let args = call.arguments as? [String: Any],
                      let paths = args["paths"] as? [String] else {
                    result(FlutterError(code: "BAD_ARGS", message: "Missing args", details: nil))
                    return
                }
                recognize(paths: paths, result: result)
            case "analyze":
                guard let args = call.arguments as? [String: Any],
                      let paths = args["paths"] as? [String] else {
                    result(FlutterError(code: "BAD_ARGS", message: "Missing args", details: nil))
                    return
                }
                analyze(paths: paths, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func recognize(paths: [String], result: @escaping FlutterResult) {
        let group = DispatchGroup()
        var outputs = Array(repeating: [String: Any](), count: paths.count)

        for (i, path) in paths.enumerated() {
            group.enter()
            guard let uiImage = UIImage(contentsOfFile: path), let cgImage = uiImage.cgImage else {
                outputs[i] = ["path": path, "text": ""]
                group.leave(); continue
            }
            let req = VNRecognizeTextRequest { req, _ in
                let obs = req.results as? [VNRecognizedTextObservation] ?? []
                let lines = obs.compactMap { $0.topCandidates(1).first?.string }
                outputs[i] = ["path": path, "text": lines.joined(separator: "\n")]
                group.leave()
            }
            req.recognitionLevel = .accurate
            req.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do { try handler.perform([req]) } catch {
                outputs[i] = ["path": path, "text": ""]
                group.leave()
            }
        }

        group.notify(queue: .main) { result(outputs) }
    }

    private static func analyze(paths: [String], result: @escaping FlutterResult) {
        let group = DispatchGroup()
        var outputs = Array(repeating: [String: Any](), count: paths.count)

        for (i, path) in paths.enumerated() {
            group.enter()
            guard let uiImage = UIImage(contentsOfFile: path), let cgImage = uiImage.cgImage else {
                outputs[i] = ["path": path, "text": "", "lines": [], "qrcodes": []]
                group.leave(); continue
            }

            let textReq = VNRecognizeTextRequest()
            textReq.recognitionLevel = .accurate
            textReq.usesLanguageCorrection = true

            let qrReq = VNDetectBarcodesRequest()
            qrReq.symbologies = [.QR]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([textReq, qrReq])
                // Full text
                let obs = (textReq.results as? [VNRecognizedTextObservation]) ?? []
                let lines = obs.compactMap { o -> [String: Any]? in
                    guard let txt = o.topCandidates(1).first?.string else { return nil }
                    // Vision bounding boxes are normalized, origin bottom-left. Convert to top-left.
                    let r = o.boundingBox
                    let topLeftY = 1.0 - (r.origin.y + r.size.height)
                    let box: [String: Double] = ["l": r.origin.x, "t": topLeftY, "w": r.size.width, "h": r.size.height]
                    return ["text": txt, "box": box]
                }
                let fullText = obs.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")

                // QR codes
                let qrObs = (qrReq.results as? [VNBarcodeObservation]) ?? []
                let qrs: [[String: Any]] = qrObs.map { o in
                    let r = o.boundingBox
                    let topLeftY = 1.0 - (r.origin.y + r.size.height)
                    let box: [String: Double] = ["l": r.origin.x, "t": topLeftY, "w": r.size.width, "h": r.size.height]
                    return ["value": o.payloadStringValue ?? "", "box": box]
                }

                outputs[i] = ["path": path, "text": fullText, "lines": lines, "qrcodes": qrs]
            } catch {
                outputs[i] = ["path": path, "text": "", "lines": [], "qrcodes": []]
            }
            group.leave()
        }

        group.notify(queue: .main) { result(outputs) }
    }
}
