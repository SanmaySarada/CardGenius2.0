#!/usr/bin/env python3
"""
Simple script to get rewards for a card by name.
Usage: python3 get_card_rewards.py "Card Name"
"""

import sys
import csv
import re
from pathlib import Path

def normalize_card_name(name):
    """Normalize card name for comparison."""
    name = re.sub(r'^\d+\.?\s*', '', name)
    name = name.strip()
    name = re.sub(r'\s+\d+\.?\d*%$', '', name)
    name = re.sub(r'\s+$', '', name)
    return name.lower()

def find_card_rewards(card_name, csv_path):
    """Find card rewards in CSV file."""
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        normalized_target = normalize_card_name(card_name)
        
        # Try exact match first
        for row in reader:
            csv_card_name = row.get('Card Name', '').strip()
            if normalize_card_name(csv_card_name) == normalized_target:
                # Extract rewards (non-zero values)
                rewards = {}
                for key, value in row.items():
                    if key != 'Card Name' and value and value.strip():
                        try:
                            reward_value = float(value)
                            if reward_value > 0:
                                rewards[key] = reward_value
                        except (ValueError, TypeError):
                            pass
                return csv_card_name, rewards
        
        # Try partial match if exact match failed
        f.seek(0)
        reader = csv.DictReader(f)
        normalized_target_parts = normalized_target.split()
        
        for row in reader:
            csv_card_name = row.get('Card Name', '').strip()
            normalized_csv = normalize_card_name(csv_card_name)
            
            # Check if all words in target are in CSV card name
            if all(part in normalized_csv for part in normalized_target_parts if len(part) > 2):
                # Extract rewards (non-zero values)
                rewards = {}
                for key, value in row.items():
                    if key != 'Card Name' and value and value.strip():
                        try:
                            reward_value = float(value)
                            if reward_value > 0:
                                rewards[key] = reward_value
                        except (ValueError, TypeError):
                            pass
                return csv_card_name, rewards
    
    return None, None

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 get_card_rewards.py \"Card Name\"")
        print("\nExample: python3 get_card_rewards.py \"Chase Sapphire Reserve\"")
        sys.exit(1)
    
    card_name = sys.argv[1]
    script_dir = Path(__file__).parent
    
    # Try to find CSV file (check multiple possible locations)
    csv_paths = [
        script_dir / 'card_rewards_matrix_refinedsix.csv',
        script_dir / 'scraper' / 'card_rewards_matrix.csv',
        script_dir / 'Core' / 'Resources' / 'card_rewards_matrix.csv',
    ]
    
    csv_path = None
    for path in csv_paths:
        if path.exists():
            csv_path = path
            break
    
    if not csv_path:
        print(f"❌ Error: No CSV file found. Checked:")
        for path in csv_paths:
            print(f"   - {path}")
        sys.exit(1)
    
    found_name, rewards = find_card_rewards(card_name, csv_path)
    
    if not found_name:
        print(f"❌ Card not found: {card_name}")
        sys.exit(1)
    
    # Display results
    print(f"✅ Card: {found_name}\n")
    
    # Find everywhere baseline
    everywhere_value = rewards.get('Everywhere', 0)
    
    if not rewards:
        print("No rewards found")
    else:
        # Separate rewards above baseline from baseline rewards
        meaningful_rewards = {k: v for k, v in rewards.items() if v > everywhere_value}
        baseline_rewards = {k: v for k, v in rewards.items() if v == everywhere_value and k != 'Everywhere'}
        
        # Show meaningful rewards
        if meaningful_rewards:
            print("Rewards (above baseline):")
            print("-" * 60)
            sorted_rewards = sorted(meaningful_rewards.items(), key=lambda x: x[1], reverse=True)
            for category, percentage in sorted_rewards:
                print(f"  {category}: {percentage}%")
        
        # Show baseline info
        if everywhere_value > 0:
            print(f"\n📊 Baseline (Everywhere): {everywhere_value}%")
            print(f"   (All other categories earn at least {everywhere_value}%)")
        
        print(f"\nTotal reward categories: {len(meaningful_rewards) + len(baseline_rewards) + (1 if everywhere_value > 0 else 0)}")

if __name__ == '__main__':
    main()
