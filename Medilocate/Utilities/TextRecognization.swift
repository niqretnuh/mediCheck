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
            if let error = error {
                print("Error during text recognition: \(error)")
                DispatchQueue.main.async {
                    completion("Error recognizing text")
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    completion("No text detected")
                }
                return
            }
            
            let recognizedStrings = observations.flatMap { observation in
                observation.topCandidates(5).map { $0.string }
            }
            
            let resultText = recognizedStrings.joined(separator: ", ")
            print("OCR Result: \(resultText)")  // Debug print
            
            DispatchQueue.main.async {
                // Fallback to "No text detected" if resultText is empty
                completion(resultText.isEmpty ? "No text detected" : resultText)
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
