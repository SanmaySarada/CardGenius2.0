#!/usr/bin/env python3
"""
Parse tempcards.txt and create JSON files for each card with rewards.
"""

import re
import json
import csv
import os
from pathlib import Path

def is_percentage(line):
    """Check if line contains a percentage value."""
    line = line.strip()
    # Match patterns like "10%", "6.25%", "3.75%", etc.
    return bool(re.match(r'^\d+\.?\d*%\s*$', line))

def is_number_line(line):
    """Check if line is a number or condition (should be ignored)."""
    line = line.strip()
    if not line:
        return False
    
    # Ignore lines with common condition patterns
    condition_patterns = [
        r'^up to',
        r'limited to',
        r'^\d+[km]$',
        r'^\$\d+',
        r'per calendar year',
        r'per year',
        r'^\d+x',
        r'x points',
        r'x miles',
        r'points',
        r'miles$',
        r'points$'
    ]
    
    for pattern in condition_patterns:
        if re.search(pattern, line.lower()):
            return True
    
    # If it's just a number, ignore it
    try:
        float(line)
        return True
    except ValueError:
        pass
    
    return False

def normalize_card_name(name):
    """Normalize card name for comparison."""
    # Remove leading numbers and periods
    name = re.sub(r'^\d+\.?\s*', '', name)
    # Strip whitespace
    name = name.strip()
    # Remove trailing percentages and extra info (e.g., "Card Name 5%" -> "Card Name")
    name = re.sub(r'\s+\d+\.?\d*%$', '', name)
    # Remove multiple trailing spaces
    name = re.sub(r'\s+$', '', name)
    # Remove special characters that might differ
    name = re.sub(r'[®℠™]', '', name)
    return name.lower()

def load_csv_card_names(csv_path):
    """Load all card names from the CSV file."""
    card_names = set()
    if not os.path.exists(csv_path):
        print(f"Warning: CSV file not found at {csv_path}")
        return card_names
    
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                card_name = row.get('Card Name', '').strip()
                if card_name:
                    card_names.add(normalize_card_name(card_name))
    except Exception as e:
        print(f"Error reading CSV: {e}")
    
    return card_names

def parse_tempcards_file(file_path):
    """Parse tempcards.txt and extract card information."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except UnicodeDecodeError:
        # Try with different encoding
        with open(file_path, 'r', encoding='utf-8-sig') as f:
            lines = f.readlines()
    
    # Filter out completely empty lines at the start
    while lines and not lines[0].strip():
        lines = lines[1:]
    
    if not lines or all(not line.strip() for line in lines):
        print(f"⚠️  Warning: File appears to be empty. Please save tempcards.txt first!")
        return []
    
    cards = []
    current_card = None
    current_percentage = None
    
    i = 0
    while i < len(lines):
        line = lines[i].rstrip('\n')
        original_line = line
        line = line.strip()
        
        # Skip empty lines
        if not line:
            i += 1
            continue
        
        # Check if line contains a card name pattern (look for "X. Card Name")
        # Handle both standalone and embedded card names
        card_pattern_match = None
        card_pattern_start = -1
        card_pattern_end = -1
        
        # First try if line starts with card pattern
        line_start_match = re.match(r'^(\d+)\.\s+(.+)$', line)
        if line_start_match:
            card_pattern_match = line_start_match
            card_pattern_start = 0
            card_pattern_end = len(line)
        else:
            # Search anywhere in line for embedded pattern
            search_match = re.search(r'(\d+)\.\s+([^\d]+?)(?:\s*$|\s+\d+\.?\d*%)', original_line)
            if search_match:
                card_pattern_match = search_match
                card_pattern_start = search_match.start()
                card_pattern_end = search_match.end()
        
        if card_pattern_match:
            # Save previous card if it has rewards
            if current_card and current_card['rewards']:
                cards.append(current_card)
            
            # Extract card name
            card_number = card_pattern_match.group(1)
            card_name = card_pattern_match.group(2).strip()
            
            # Clean up card name - remove trailing whitespace, periods, and percentages
            card_name = re.sub(r'\s+\d+\.?\d*%$', '', card_name)  # Remove trailing percentage
            card_name = re.sub(r'\s+$', '', card_name)  # Remove trailing whitespace
            card_name = re.sub(r'\.\s*$', '', card_name)  # Remove trailing period
            
            # Start new card
            current_card = {
                'name': card_name,
                'rewards': {}
            }
            current_percentage = None
            
            # Check if there's a percentage after the card name on the same line
            after_card = original_line[card_pattern_end:].strip()
            if after_card:
                if is_percentage(after_card):
                    percentage_match = re.search(r'(\d+\.?\d*)%', after_card)
                    if percentage_match:
                        current_percentage = float(percentage_match.group(1))
            
            i += 1
            continue
        
        # Check if line is a percentage
        if is_percentage(line):
            percentage_match = re.search(r'(\d+\.?\d*)%', line)
            if percentage_match:
                current_percentage = float(percentage_match.group(1))
            i += 1
            continue
        
        # Check if line should be ignored
        if is_number_line(line):
            current_percentage = None
            i += 1
            continue
        
        # If we have a current card and percentage, this should be a category
        if current_card and current_percentage is not None:
            # Check if this line contains a new card embedded
            embedded_card = re.search(r'(\d+)\.\s+([^\d]+?)(?:\s*$|\s+\d+\.?\d*%)', original_line)
            if embedded_card:
                # Extract category before the embedded card
                category = original_line[:embedded_card.start()].strip()
                if category:
                    # Clean category
                    category = re.sub(r'\s+', ' ', category)
                    if category not in current_card['rewards'] or current_percentage > current_card['rewards'][category]:
                        current_card['rewards'][category] = current_percentage
                
                # Process the new card immediately (will be handled in next iteration)
                # But we need to save current card and start new one
                if current_card['rewards']:
                    cards.append(current_card)
                
                # Extract and start new card
                new_card_name = embedded_card.group(2).strip()
                new_card_name = re.sub(r'\s+$', '', new_card_name)
                new_card_name = re.sub(r'\.\s*$', '', new_card_name)
                
                current_card = {
                    'name': new_card_name,
                    'rewards': {}
                }
                current_percentage = None
                
                # Check if percentage follows on same line
                after_new_card = original_line[embedded_card.end():].strip()
                if after_new_card and is_percentage(after_new_card):
                    percentage_match = re.search(r'(\d+\.?\d*)%', after_new_card)
                    if percentage_match:
                        current_percentage = float(percentage_match.group(1))
            else:
                # Regular category line
                category = line.strip()
                # Clean category
                category = re.sub(r'\s+', ' ', category)
                if category:
                    # Add reward (take higher percentage if exists)
                    if category not in current_card['rewards'] or current_percentage > current_card['rewards'][category]:
                        current_card['rewards'][category] = current_percentage
                current_percentage = None
            
            i += 1
            continue
        
        # Otherwise, this might be a continuation or something else - skip it
        i += 1
    
    # Add the last card if it has rewards
    if current_card and current_card['rewards']:
        cards.append(current_card)
    
    return cards

def main():
    script_dir = Path(__file__).parent
    tempcards_path = script_dir / 'tempcards.txt'
    csv_path = script_dir / 'card_rewards_matrix_refinedsix.csv'
    output_dir = script_dir / 'card_json_output'
    
    # Check if file exists and has content
    if not tempcards_path.exists():
        print(f"❌ Error: File not found: {tempcards_path}")
        print("   Please make sure tempcards.txt exists in the project root.")
        return
    
    file_size = tempcards_path.stat().st_size
    if file_size == 0:
        print(f"❌ Error: File is empty (0 bytes): {tempcards_path}")
        print("   The file appears to be unsaved in your IDE.")
        print("   Please save tempcards.txt first, then run this script again.")
        return
    
    print(f"📄 Reading {tempcards_path} ({file_size} bytes)...")
    
    # Create output directory
    output_dir.mkdir(exist_ok=True)
    
    # Load card names from CSV for verification
    csv_card_names = load_csv_card_names(csv_path)
    
    # Parse tempcards.txt
    cards = parse_tempcards_file(tempcards_path)
    
    print(f"Found {len(cards)} cards in tempcards.txt")
    print(f"Found {len(csv_card_names)} cards in CSV file\n")
    
    # Create JSON file for each card
    found_count = 0
    not_found_count = 0
    
    for card in cards:
        # Check if card exists in CSV
        normalized_name = normalize_card_name(card['name'])
        in_csv = normalized_name in csv_card_names
        
        # Create JSON structure
        json_data = {
            'card': card['name'],
            'in_csv': in_csv,
            'rewards': {}
        }
        
        # Convert rewards to percentage strings
        for category, percentage in card['rewards'].items():
            json_data['rewards'][category] = f"{percentage}%"
        
        # Create safe filename from card name
        safe_name = re.sub(r'[^\w\s-]', '', card['name'])
        safe_name = re.sub(r'[-\s]+', '_', safe_name)
        safe_name = safe_name[:100]  # Limit filename length
        if not safe_name:
            safe_name = f"card_{found_count + not_found_count}"
        
        json_file = output_dir / f"{safe_name}.json"
        
        # Write JSON file
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, indent=2, ensure_ascii=False)
        
        if in_csv:
            found_count += 1
        else:
            not_found_count += 1
            print(f"⚠️  Card not found in CSV: {card['name']}")
    
    print(f"\n✅ Created {len(cards)} JSON files in {output_dir}")
    print(f"   Found in CSV: {found_count}")
    print(f"   Not found in CSV: {not_found_count}")

if __name__ == '__main__':
    main()