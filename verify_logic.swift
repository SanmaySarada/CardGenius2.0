import Foundation

// Absolute Path
let csvPath = "/Users/sanmaysarada/CardGenius2.0/Core/Resources/card_rewards_matrix.csv"

// CSV Parser Logic
func parseRewardsMatrix(path: String) -> [String: [String: Double]] {
    do {
        print("Reading file at: \(path)")
        let content = try String(contentsOfFile: path, encoding: .utf8)
        let rows = content.components(separatedBy: "\n")
        
        guard let headerRow = rows.first else { return [:] }
        let headers = headerRow.components(separatedBy: ",")
        print("Headers count: \(headers.count)")
        
        var matrix: [String: [String: Double]] = [:]
        
        for (i, row) in rows.dropFirst().enumerated() {
            if row.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            
            let columns = parseCSVRow(row)
            
            // Debug first failure
            if i == 0 {
                print("First row columns: \(columns.count)")
                if columns.count != headers.count {
                    print("Mismatch! Headers: \(headers.count), Columns: \(columns.count)")
                }
            }
            
            // Relaxed check: Just ensure we have enough columns for the ones we care about
            // Or just iterate up to min(headers.count, columns.count)
            
            let cardName = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if cardName.isEmpty { continue }
            
            var rewards: [String: Double] = [:]
            
            for (index, header) in headers.enumerated() {
                if index == 0 { continue }
                if index >= columns.count { break } // Stop if we run out of columns
                
                let category = header.trimmingCharacters(in: .whitespacesAndNewlines)
                let valueStr = columns[index].trimmingCharacters(in: .whitespacesAndNewlines)
                if let value = parseRewardValue(valueStr) {
                    rewards[category] = value
                }
            }
            matrix[cardName] = rewards
        }
        return matrix
    } catch {
        print("Error: \(error)")
        return [:]
    }
}

func parseCSVRow(_ row: String) -> [String] {
    var result: [String] = []
    var current = ""
    var insideQuotes = false
    for char in row {
        if char == "\"" { insideQuotes.toggle() }
        else if char == "," && !insideQuotes {
            result.append(current)
            current = ""
        } else { current.append(char) }
    }
    result.append(current)
    return result
}

func parseRewardValue(_ value: String) -> Double? {
    let cleaned = value.replacingOccurrences(of: ",", with: "")
                       .replacingOccurrences(of: "%", with: "")
                       .replacingOccurrences(of: "x", with: "")
                       .trimmingCharacters(in: .whitespacesAndNewlines)
    return Double(cleaned)
}

// Logic to Test
func getBestReward(merchantName: String, categoryName: String, rewards: [String: Double]) -> Double {
    var maxVal = 0.0
    
    // 1. Check Merchant Name
    let merchantNameLower = merchantName.lowercased()
    for (key, val) in rewards {
        if merchantNameLower.contains(key.lowercased()) && key.count > 3 {
            if val > maxVal { 
                // print("  Found match by Name: \(key) -> \(val)") 
            }
            maxVal = max(maxVal, val)
        }
    }
    
    // 2. Check Category
    if let val = rewards[categoryName] {
        if val > maxVal { 
            // print("  Found match by Category: \(categoryName) -> \(val)") 
        }
        maxVal = max(maxVal, val)
    }
    
    // 3. Check Partial Category
    for (key, val) in rewards {
        if key.lowercased().contains(categoryName.lowercased()) {
            maxVal = max(maxVal, val)
        }
    }
    
    // 4. Fallback
    let fallback = rewards["Everywhere"] ?? rewards["Other purchases"] ?? 0.0
    maxVal = max(maxVal, fallback)
    
    return maxVal
}

// Run Test
let matrix = parseRewardsMatrix(path: csvPath)
print("Loaded \(matrix.count) cards.")

// Test Case 1: H-E-B (Should match H-E-B column if present)
print("\n--- Testing H-E-B ---")
for (card, rewards) in matrix {
    let reward = getBestReward(merchantName: "H-E-B", categoryName: "Grocery", rewards: rewards)
    if reward > 3.0 { 
        print("\(card): \(reward)%")
    }
}

// Test Case 2: Target
print("\n--- Testing Target ---")
for (card, rewards) in matrix {
    let reward = getBestReward(merchantName: "Target", categoryName: "Department Stores", rewards: rewards)
    if reward >= 5.0 {
        print("\(card): \(reward)%")
    }
}
