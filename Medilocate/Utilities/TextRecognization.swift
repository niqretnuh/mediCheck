import Foundation
import Vision
import UIKit

class TextRecognition {
    static let shared = TextRecognition()

    private init() {}

    func recognizeText(in image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("No text detected")
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("No text detected")
                return
            }

            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            let resultText = recognizedStrings.joined(separator: ", ")

            DispatchQueue.main.async {
                completion(resultText)
            }
        }

        do {
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the text-recognition request: \(error).")
            completion("Error recognizing text")
        }
    }
}
