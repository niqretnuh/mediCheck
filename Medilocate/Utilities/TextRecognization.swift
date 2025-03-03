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
            
            // Sort observations by bounding box area (largest first)
            let sortedObservations = observations.sorted { obs1, obs2 in
                let area1 = obs1.boundingBox.width * obs1.boundingBox.height
                let area2 = obs2.boundingBox.width * obs2.boundingBox.height
                return area1 > area2
            }
            
            // Extract the top candidate string from each sorted observation
            let recognizedStrings = sortedObservations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            // Join the recognized strings with newline for clarity
            let resultText = recognizedStrings.joined(separator: "\n")
            print("OCR Result: \(resultText)")  // Debug print
            
            DispatchQueue.main.async {
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
