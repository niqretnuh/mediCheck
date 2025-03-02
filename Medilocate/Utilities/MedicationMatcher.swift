import Foundation
import UIKit

// Use KNN algorithm to match medications
/// Note: Want to change this to semantic embeddings. Will have to run on Python -- more on this after connecting with backend
class MedicationMatcher {
    /// Temporary implementation:  load an array of medication names from the CSV file.
    var medicationDataset: [String] = []

    init(csvFileName: String) {
        self.medicationDataset = loadMedications(from: csvFileName)
    }
    
    /// TODO: this loads data from csv. Needs to go
    private func loadMedications(from csvFileName: String) -> [String] {
        var medications: [String] = []
        guard let fileUrl = Bundle.main.url(forResource: csvFileName, withExtension: "csv") else {
            print("CSV file \(csvFileName).csv not found in bundle.")
            return medications
        }
        
        do {
            let content = try String(contentsOf: fileUrl, encoding: .utf8)
            medications = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            
        } catch {
            print("Error reading CSV file: \(error.localizedDescription)")
        }
        
        return medications
    }
    
    // Using Levenshtein distance
    func levenshteinDistance(_ s: String, _ t: String) -> Int {
        let sArray = Array(s)
        let tArray = Array(t)
        let sCount = sArray.count
        let tCount = tArray.count
        
        var dist = Array(repeating: Array(repeating: 0, count: tCount + 1), count: sCount + 1)
        
        for i in 0...sCount {
            dist[i][0] = i
        }
        for j in 0...tCount {
            dist[0][j] = j
        }
        
        for i in 1...sCount {
            for j in 1...tCount {
                if sArray[i - 1] == tArray[j - 1] {
                    dist[i][j] = dist[i - 1][j - 1]
                } else {
                    dist[i][j] = min(
                        dist[i - 1][j] + 1,    // Deletion
                        dist[i][j - 1] + 1,    // Insertion
                        dist[i - 1][j - 1] + 1 // Substitution
                    )
                }
            }
        }
        
        return dist[sCount][tCount]
    }
    
    func findClosestMedications(for query: String, k: Int = 3) -> [String] {
        let distances = medicationDataset.map { medication in
            // Calculate the Levenshtein distance after lowercasing both strings for normalization.
            (medication, levenshteinDistance(query.lowercased(), medication.lowercased()))
        }
        // Sort medications by their distance (ascending order).
        let sortedMedications = distances.sorted { $0.1 < $1.1 }
        return Array(sortedMedications.prefix(k)).map { $0.0 }
    }
}


