"""
Credit card rewards analyzer for locations.

This script:
1. Takes a location (address or place name) as input
2. Looks up the place using Google Places API
3. Maps the place to reward categories (e.g., "Target", "Restaurants", "Gas stations")
4. Finds the best credit cards from the user's collection for that location
5. Displays ranked results with reward rates and offer details
"""

import os
import re
import sys
import requests
from dotenv import load_dotenv
from map_to_category import (
    map_place_to_categories,
    build_search_terms,
    FALLBACK_KEYWORDS,
)
import pandas as pd
from typing import List, Optional, Tuple

load_dotenv()

# -----------------------------------------------------------------------------
# Configuration: User's credit card collection
# -----------------------------------------------------------------------------
USER_CARDS: List[str] = [
    "Target REDcard",
    "Capital One Venture X Rewards Credit Card",
    "American Express® Gold Card",
    "Chase Sapphire Reserve®",
    "U.S. Bank Altitude® Go",
]


# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

def _generate_offer_text(
    card_row: pd.Series, search_terms: List[str], all_columns: List[str]
) -> str:
    """
    Generates reward offer text for a card from the rewards matrix data.
    
    Args:
        card_row: Pandas Series representing one row from the rewards matrix
        search_terms: List of category terms to prioritize
        all_columns: List of all category columns in the dataframe
        
    Returns:
        Formatted offer text like "4% — Restaurants | 1% — Everywhere"
    """
    # Extract all non-zero reward categories from the card
    offers = []
    for col in all_columns:
        if col == "Card Name":
            continue
        value = card_row.get(col, 0.0)
        
        # Convert to numeric if needed
        if isinstance(value, str):
            cleaned = str(value).replace(",", "").strip()
            match = re.search(r"(-?\d+(?:\.\d+)?)", cleaned)
            if match:
                value = float(match.group(1))
            else:
                value = 0.0
        else:
            value = float(value) if pd.notna(value) else 0.0
        
        if value > 0:
            offers.append((col, value))
    
    if not offers:
        return ""
    
    # Only show categories that match search terms
    # Exclude all other unrelated categories (including fallback categories)
    lowered_terms = [term.lower() for term in search_terms]
    matched_offers = []
    
    for category, rate in offers:
        category_lower = category.lower()
        # Only include categories that match search terms
        if any(term in category_lower for term in lowered_terms):
            matched_offers.append((category, rate))
        # Otherwise, exclude this category (don't show unrelated offers)
    
    # Sort by reward rate (highest first)
    matched_offers.sort(key=lambda x: x[1], reverse=True)
    
    # Only show matched offers (the actual category being searched)
    display_offers = matched_offers
    
    # Format as "X% — Category Name" (remove trailing zeros for whole numbers)
    formatted = []
    for category, rate in display_offers:
        # Format rate: remove trailing zeros if it's a whole number
        if rate == int(rate):
            rate_str = str(int(rate))
        else:
            rate_str = str(rate).rstrip("0").rstrip(".")
        formatted.append(f"{rate_str}% — {category}")
    return " | ".join(formatted)


def get_best_cards_for_category(
    category: str,
    top_n: int = 20,
    matrix_csv_path: str = "card_rewards_matrix.csv",
    card_whitelist: Optional[List[str]] = None,
    categories: Optional[List[str]] = None,
) -> List[Tuple[str, float, str]]:
    """
    Finds the best credit cards for a given reward category.
    
    This function:
    1. Loads the rewards matrix CSV
    2. Filters to user's cards (or provided whitelist)
    3. Finds reward columns matching the category
    4. Scores each card by maximum reward rate
    5. Returns top N cards with reward rates and offer text
    
    Args:
        category: Primary reward category name
        top_n: Number of top cards to return
        matrix_csv_path: Path to rewards matrix CSV
        card_whitelist: Optional list of cards to filter to (uses USER_CARDS if None)
        categories: Optional list of multiple categories to consider together
        
    Returns:
        List of tuples: (card_name, reward_rate, offer_text), sorted by reward rate descending
    """
    # Load rewards matrix
    df = pd.read_csv(matrix_csv_path)
    
    if "Card Name" not in df.columns:
        raise ValueError("Matrix CSV must have a 'Card Name' column.")
    
    # Filter to user's cards (or provided whitelist)
    whitelist = card_whitelist if card_whitelist is not None else USER_CARDS
    
    if whitelist:
        whitelist_lower = {name.lower() for name in whitelist}
        df = df[df["Card Name"].str.lower().isin(whitelist_lower)].reset_index(drop=True)
        
        # Add missing cards with zero rewards (so all user cards appear in results)
        existing_lower = set(df["Card Name"].str.lower())
        zero_template = {col: 0.0 for col in df.columns if col != "Card Name"}
        missing_rows = []
        for card_name in whitelist:
            if card_name.lower() in existing_lower:
                continue
            missing_rows.append({"Card Name": card_name, **zero_template})
        if missing_rows:
            df = pd.concat([df, pd.DataFrame(missing_rows)], ignore_index=True)
    
    if df.empty:
        return []
    
    # Build search terms from category/categories
    # If multiple categories provided, combine their search terms
    if categories:
        terms: List[str] = []
        for cat in categories:
            terms.extend(build_search_terms(cat, list(df.columns)))
        # Deduplicate while preserving order
        seen = set()
        search_terms = []
        for t in terms:
            tl = t.lower()
            if tl in seen:
                continue
            seen.add(tl)
            search_terms.append(t)
    else:
        search_terms = build_search_terms(category, list(df.columns))
    
    # Find reward columns that match the search terms
    candidate_columns = [
        column
        for column in df.columns
        if column != "Card Name" and any(term.lower() in column.lower() for term in search_terms)
    ]
    
    # Fallback to generic "everywhere" columns if no specific match
    if not candidate_columns:
        candidate_columns = [
            column
            for column in df.columns
            if column != "Card Name"
            and any(keyword in column.lower() for keyword in FALLBACK_KEYWORDS)
        ]
    
    if not candidate_columns:
        return []
    
    # Convert reward values to numeric and aggregate
    # For each card, take the maximum reward rate across matching columns
    numeric_columns: dict[str, pd.Series] = {}
    for column in candidate_columns:
        cleaned_series = (
            df[column]
            .astype(str)
            .str.replace(",", "", regex=False)
            .str.extract(r"(-?\d+(?:\.\d+)?)", expand=False)
        )
        numeric_columns[column] = pd.to_numeric(cleaned_series, errors="coerce")
    
    numeric_df = pd.DataFrame(numeric_columns).fillna(0.0)
    aggregated_series = numeric_df.max(axis=1)
    
    if aggregated_series.empty:
        return []
    
    # Sort cards by reward rate (highest first)
    scores_df = pd.DataFrame({
        "Card Name": df["Card Name"],
        "score": aggregated_series,
    }).sort_values("score", ascending=False, kind="mergesort")
    
    # Build results with card name, reward rate, and offer text
    # Generate offer text directly from the matrix data
    all_columns = [col for col in df.columns if col != "Card Name"]
    results: List[Tuple[str, float, str]] = []
    for _, score_row in scores_df.head(top_n).iterrows():
        card_name = score_row["Card Name"]
        reward_value = float(score_row["score"]) if pd.notna(score_row["score"]) else 0.0
        
        # Only generate offer text if there's a match (reward_value > 0)
        # Otherwise, show empty offer text
        if reward_value > 0:
            # Get the full card row from the original dataframe
            card_row = df[df["Card Name"] == card_name].iloc[0]
            # Generate offer text from the matrix data (only relevant categories)
            offer_text = _generate_offer_text(card_row, search_terms, all_columns)
        else:
            offer_text = ""
        
        results.append((card_name, reward_value, offer_text))
    
    return results


# -----------------------------------------------------------------------------
# Main Script: Google Places API lookup and card recommendation
# -----------------------------------------------------------------------------

# Validate API key
API_KEY = os.environ.get("GOOGLE_PLACES_API_KEY")
if not API_KEY:
    print("Set GOOGLE_PLACES_API_KEY first.")
    sys.exit(1)

# Validate command line arguments
if len(sys.argv) < 2:
    print("Usage: python map.py '1600 Amphitheatre Pkwy, Mountain View, CA'")
    sys.exit(1)

# Get address from command line arguments
address = " ".join(sys.argv[1:])

# Look up place using Google Places API
url = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json"
params = {
    "input": address,
    "inputtype": "textquery",
    "fields": "place_id,name,formatted_address,types",
    "key": API_KEY,
}

resp = requests.get(url, params=params, timeout=10)
resp.raise_for_status()
data = resp.json()

# Extract place information
cands = data.get("candidates", [])
if not cands:
    print("No place found.")
    sys.exit(0)

place = cands[0]  # Use the best match

# Display place information
print("Name:", place.get("name"))
print("Address:", place.get("formatted_address"))
print("Place ID:", place.get("place_id"))
print("Types:", place.get("types", []))

# Map place to reward categories (both brand-specific and default)
brand_cat, default_cat = map_place_to_categories(
    place.get("name", ""), place.get("types", [])
)
categories_used = [c for c in [brand_cat, default_cat] if c]
category = brand_cat or default_cat or "Other purchases"

print("Mapped Category:", category)
if len(categories_used) > 1:
    print("Also considering categories:", ", ".join(categories_used[1:]))

# Find best cards for this location
top_cards = get_best_cards_for_category(
    category, categories=categories_used or None
)

# Display results
if not top_cards:
    print("No rewards data found for this category.")
else:
    print("Top cards for category:")
    for rank, (card, reward_value, offer_text) in enumerate(top_cards, start=1):
        display_offer = f" — {offer_text}" if offer_text else ""
        print(f"  {rank}. {card}: {reward_value}{display_offer}")
