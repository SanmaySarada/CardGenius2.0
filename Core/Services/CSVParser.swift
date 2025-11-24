//
//  CSVParser.swift
//  CardGenius
//
//  Parses the rewards matrix CSV
//

import Foundation

class CSVParser {
    static let shared = CSVParser()
    
    private init() {}
    
    func parseRewardsMatrix() -> [String: [String: Double]] {
        guard let path = Bundle.main.path(forResource: "card_rewards_matrix_temp2", ofType: "csv") else {
            print("CSV file not found")
            return [:]
        }
        
        do {
            let content = try String(contentsOfFile: path)
            let rows = content.components(separatedBy: "\n")
            
            guard let headerRow = rows.first else { return [:] }
            let headers = headerRow.components(separatedBy: ",")
            
            var matrix: [String: [String: Double]] = [:]
            
            for row in rows.dropFirst() {
                let columns = parseCSVRow(row)
                // Relaxed check: Ensure we have at least the Card Name
                if columns.count > 0 {
                    let cardName = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    if cardName.isEmpty { continue }
                    
                    var rewards: [String: Double] = [:]
                    
                    for (index, header) in headers.enumerated() {
                        if index == 0 { continue }
                        // Stop if row has fewer columns than headers
                        if index >= columns.count { break }
                        
                        let category = header.trimmingCharacters(in: .whitespacesAndNewlines)
                        let valueStr = columns[index].trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Parse value (handle "3.0%", "3x", etc.)
                        if let value = parseRewardValue(valueStr) {
                            rewards[category] = value
                        }
                    }
                    
                    matrix[cardName] = rewards
                }
            }
            
            return matrix
        } catch {
            print("Error parsing CSV: \(error)")
            return [:]
        }
    }
    
    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false
        
        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        return result
    }
    
    private func parseRewardValue(_ value: String) -> Double? {
        let cleaned = value.replacingOccurrences(of: ",", with: "")
                           .replacingOccurrences(of: "%", with: "")
                           .replacingOccurrences(of: "x", with: "")
                           .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned)
    }
}
