#!/usr/bin/env python3
"""
Update CSV files with rewards data from JSON files.
Apply "Everywhere" as minimum baseline for all other categories.
"""

import json
import csv
import re
from pathlib import Path
from collections import defaultdict

def normalize_card_name(name):
    """Normalize card name for comparison."""
    # Remove leading numbers and periods
    name = re.sub(r'^\d+\.?\s*', '', name)
    # Strip whitespace
    name = name.strip()
    # Remove trailing percentages and extra info
    name = re.sub(r'\s+\d+\.?\d*%$', '', name)
    # Remove multiple trailing spaces
    name = re.sub(r'\s+$', '', name)
    return name.lower()

def parse_percentage(value):
    """Parse percentage string to float."""
    if isinstance(value, str):
        # Remove % sign and convert
        value = value.replace('%', '').strip()
    try:
        return float(value)
    except (ValueError, TypeError):
        return 0.0

def load_json_cards(json_dir):
    """Load all card data from JSON files."""
    cards_data = {}
    
    for json_file in sorted(json_dir.glob('*.json')):
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            card_name = data['card']
            rewards = data.get('rewards', {})
            
            # Parse rewards and apply "Everywhere as minimum" rule
            parsed_rewards = {}
            everywhere_value = None
            
            # First pass: parse all rewards and find "Everywhere"
            for category, percentage_str in rewards.items():
                value = parse_percentage(percentage_str)
                parsed_rewards[category] = value
                if category == "Everywhere":
                    everywhere_value = value
            
            # Second pass: apply "Everywhere" as minimum if it exists
            if everywhere_value is not None:
                for category in parsed_rewards:
                    if category != "Everywhere":
                        # If category value is less than everywhere, set to everywhere
                        if parsed_rewards[category] < everywhere_value:
                            parsed_rewards[category] = everywhere_value
            
            cards_data[card_name] = {
                'rewards': parsed_rewards,
                'everywhere_baseline': everywhere_value
            }
    
    return cards_data

def find_card_in_csv(card_name, csv_rows, csv_headers):
    """Find card row index in CSV."""
    normalized_target = normalize_card_name(card_name)
    
    for i, row in enumerate(csv_rows):
        if len(row) > 0:
            csv_card_name = row[0].strip()
            normalized_csv = normalize_card_name(csv_card_name)
            if normalized_target == normalized_csv:
                return i
    return None

def match_category_to_csv_column(category, csv_headers):
    """Match JSON category to CSV column name."""
    # Try exact match first
    if category in csv_headers:
        return csv_headers.index(category)
    
    # Try normalized match
    normalized_category = category.lower().strip()
    for i, header in enumerate(csv_headers):
        if header.lower().strip() == normalized_category:
            return i
    
    # Try partial match for common variations
    category_lower = normalized_category
    for i, header in enumerate(csv_headers):
        header_lower = header.lower().strip()
        # Check if category is contained in header or vice versa
        if category_lower in header_lower or header_lower in category_lower:
            # Avoid false matches (e.g., "Hotel" matching "Hotels")
            if len(category_lower) > 3 and len(header_lower) > 3:
                return i
    
    return None

def update_csv_with_json_data(csv_path, json_cards, output_path):
    """Update CSV file with data from JSON cards."""
    # Read CSV
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        headers = next(reader)
        rows = list(reader)
    
    # Create mapping from JSON categories to CSV column indices
    category_to_column = {}
    for category in set(cat for card_data in json_cards.values() for cat in card_data['rewards'].keys()):
        col_idx = match_category_to_csv_column(category, headers)
        if col_idx is not None:
            category_to_column[category] = col_idx
    
    # Update rows
    updated_count = 0
    not_found_count = 0
    
    for card_name, card_data in json_cards.items():
        # Find card in CSV
        card_row_idx = find_card_in_csv(card_name, rows, headers)
        
        if card_row_idx is None:
            not_found_count += 1
            print(f"⚠️  Card not found in CSV: {card_name}")
            continue
        
        # Update rewards in CSV row
        row = rows[card_row_idx]
        # Ensure row has enough columns
        while len(row) < len(headers):
            row.append('0.0')
        
        # Apply rewards
        rewards = card_data['rewards']
        everywhere_baseline = card_data.get('everywhere_baseline')
        
        # Track which columns we've explicitly set from JSON rewards
        explicitly_set_columns = set()
        
        # First pass: Set all explicit rewards from JSON
        for category, percentage in rewards.items():
            if category == "Everywhere":
                # Set "Everywhere" column
                everywhere_col_idx = match_category_to_csv_column("Everywhere", headers)
                if everywhere_col_idx is not None:
                    row[everywhere_col_idx] = str(percentage)
                    explicitly_set_columns.add(everywhere_col_idx)
            else:
                # Set category column
                col_idx = category_to_column.get(category)
                if col_idx is not None:
                    # Ensure value is at least everywhere_baseline if it exists
                    final_value = percentage
                    if everywhere_baseline is not None and percentage < everywhere_baseline:
                        final_value = everywhere_baseline
                    row[col_idx] = str(final_value)
                    explicitly_set_columns.add(col_idx)
        
        # Second pass: Apply everywhere baseline to all other columns that are 0 or missing
        # (This sets the minimum baseline for categories not explicitly mentioned)
        if everywhere_baseline is not None and everywhere_baseline > 0:
            for i in range(1, len(headers)):  # Skip "Card Name" column
                if i < len(row) and i not in explicitly_set_columns:
                    try:
                        current_value = float(row[i]) if row[i] else 0.0
                        # If column is 0 or missing, set to everywhere baseline
                        if current_value == 0.0:
                            row[i] = str(everywhere_baseline)
                    except (ValueError, IndexError):
                        # If parsing fails, set to everywhere baseline
                        row[i] = str(everywhere_baseline)
        
        rows[card_row_idx] = row
        updated_count += 1
    
    # Write updated CSV
    with open(output_path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        writer.writerows(rows)
    
    print(f"✅ Updated {updated_count} cards in {output_path.name}")
    if not_found_count > 0:
        print(f"⚠️  {not_found_count} cards not found in CSV")

def main():
    script_dir = Path(__file__).parent
    json_dir = script_dir / 'card_json_output'
    csv_temp2_path = script_dir / 'card_rewards_matrix_refinedsix.csv'
    csv_path = script_dir / 'scraper' / 'card_rewards_matrix.csv'
    
    # Load JSON cards
    print("📄 Loading JSON card data...")
    json_cards = load_json_cards(json_dir)
    print(f"   Loaded {len(json_cards)} cards from JSON files\n")
    
    # Update both CSV files
    if csv_temp2_path.exists():
        print(f"📝 Updating {csv_temp2_path.name}...")
        update_csv_with_json_data(csv_temp2_path, json_cards, csv_temp2_path)
        print()
    
    if csv_path.exists():
        print(f"📝 Updating {csv_path.name}...")
        update_csv_with_json_data(csv_path, json_cards, csv_path)
        print()
    else:
        print(f"⚠️  File not found: {csv_path}")
    
    print("✅ Done!")

if __name__ == '__main__':
    main()
