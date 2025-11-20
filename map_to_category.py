import re
from difflib import get_close_matches

# -------------------------------------------------------------------
# 1. Category master list (from your dataset)
#    (Trimmed slightly here for clarity — you can paste the full version)
# -------------------------------------------------------------------
CATEGORIES = [
    "AAA", "AT&T", "Alaska Air", "Amazon", "Amtrak", "Athleta", "Banana Republic",
    "Barnes & Noble", "Bass Pro", "Beauty", "Bed Bath & Beyond", "Belk", "Bloomingdale",
    "Book Store", "British Air", "Bus", "Car Rental", "Choice", "Costco Gas", "Cruise",
    "Department Stores", "Dining", "Drugstore", "Electronics retailers (up to $2M spend/yr)",
    "Entertainment", "Fast Food", "Flights (Amex Travel)", "Food Delivery", "Gas",
    "Gas stations (U.S.)", "Grocery", "Grocery stores (U.S.)", "Gym", "Hilton hotels/resorts",
    "Home Improvement", "Hotel", "IHG", "JCPenney", "Kohl's", "Kroger", "Lowe's", "Lyft",
    "Macy's", "Marriott", "Marshalls", "Menards", "Old Navy", "Online retail (U.S.)",
    "Other purchases", "REI", "Restaurants", "Ride-Sharing", "Sam's Club", "Sporting Good",
    "Starbucks", "Streaming services", "Supermarkets (U.S.)", "TJ Maxx", "Target",
    "Telecommunication", "Transit", "Travel", "Walgreens", "Wayfair", "Whole Foods",
    "Wholesale Club", "Wireless telephone services (direct, U.S. providers)"
]

# -------------------------------------------------------------------
# Shared fallback/search helpers (used by ranking)
# -------------------------------------------------------------------
FALLBACK_KEYWORDS = ("everywhere", "other purchases", "all purchases", "everything else")
DEFAULT_FALLBACK_TERMS = ["Everywhere", "Other purchases"]

# -------------------------------------------------------------------
# 2. Brand → Category direct overrides
# -------------------------------------------------------------------
BRAND_OVERRIDES = {
    "target": "Target",
    "walmart": "Department Stores",
    "costco": "Wholesale Club",
    "sam's club": "Wholesale Club",
    "bjs": "Wholesale Club",
    "whole foods": "Whole Foods",
    "trader joe": "Grocery",
    "ralphs": "Grocery",
    "starbucks": "Starbucks",
    "mcdonald": "Fast Food",
    "in n out": "Fast Food",
    "chipotle": "Dining",
    "panera": "Dining",
    "shell": "Gas stations (U.S.)",
    "chevron": "Gas stations (U.S.)",
    "hilton": "Hilton hotels/resorts",
    "marriott": "Marriott",
    "hyatt": "Hotel",
    "ihg": "IHG",
    "aaa": "AAA",
    "at&t": "AT&T",
    "att": "AT&T",
    "old navy": "Old Navy",
    "marshalls": "Marshalls",
    "athleta": "Athleta",
    "banana republic": "Banana Republic",
    "barnes & noble": "Barnes & Noble",
    "barnes and noble": "Barnes & Noble",
    "bass pro": "Bass Pro",
    "belk": "Belk",
    "bloomingdale": "Bloomingdale",
    "choice": "Choice",
    "jcpenney": "JCPenney",
    "jcpenny": "JCPenney",
    "kohl's": "Kohl's",
    "kohls": "Kohl's",
    "kroger": "Kroger",
    "lowe's": "Lowe's",
    "lowes": "Lowe's",
    "lyft": "Lyft",
    "macy's": "Macy's",
    "macys": "Macy's",
    "menards": "Menards",
    "rei": "REI",
    "sam's club": "Sam's Club",
    "sams club": "Sam's Club",
    "tj maxx": "TJ Maxx",
    "walgreens": "Walgreens",
    "wayfair": "Wayfair",
}

# Robust normalization for brand matching
_NON_ALNUM_RE = re.compile(r"[^a-z0-9]+")

def _normalize_text(s: str) -> str:
    s = (s or "").lower()
    s = s.replace("&", "")
    return _NON_ALNUM_RE.sub("", s)

_NORMALIZED_BRAND_OVERRIDES = { _normalize_text(k): v for k, v in BRAND_OVERRIDES.items() }

# -------------------------------------------------------------------
# 3. Google place type → Category mappings
# -------------------------------------------------------------------
TYPE_TO_CATEGORY = {
    # Food / dining
    "restaurant": "Restaurants",
    "cafe": "Dining",
    "bar": "Dining",
    "meal_takeaway": "Takeout/Delivery (U.S.)",
    "bakery": "Dining",
    "fast_food_restaurant": "Fast Food",
    "food": "Dining",

    # Retail / shopping
    "supermarket": "Supermarkets (U.S.)",
    "grocery_or_supermarket": "Grocery",
    "department_store": "Department Stores",
    "clothing_store": "Department Stores",
    "electronics_store": "Electronics retailers (up to $2M spend/yr)",
    "home_goods_store": "Home Improvement",
    "book_store": "Book Store",
    "pharmacy": "Drugstore",
    "store": "Department Stores",

    # Travel & transport
    "gas_station": "Gas stations (U.S.)",
    "lodging": "Hotel",
    "hotel": "Hotel",
    "car_rental": "Car Rental",
    "bus_station": "Transit",
    "train_station": "Transit",
    "airport": "Travel",

    # Entertainment & recreation
    "gym": "Gym",
    "movie_theater": "Entertainment",
    "amusement_park": "Entertainment",
    "stadium": "Entertainment",
    "museum": "Entertainment",
    "night_club": "Entertainment",
    "spa": "Beauty",
}

# -------------------------------------------------------------------
# 4. Core mapping function
# -------------------------------------------------------------------
def map_place_to_category(place_name: str, types: list[str]) -> str:
    """
    Given a place name and list of Google Maps types,
    return the best-matching category from the known list.
    """
    if not place_name and not types:
        return "Other purchases"

    name_lower = (place_name or "").lower()
    name_norm = _normalize_text(place_name or "")

    # 1. Check brand overrides (e.g., Target, Whole Foods)
    # First try normalized containment to absorb punctuation/spacing variants
    for brand_norm, cat in _NORMALIZED_BRAND_OVERRIDES.items():
        if brand_norm and brand_norm in name_norm:
            return cat
    # Fallback to legacy lowercase substring (covers simple cases)
    for brand_raw, cat in BRAND_OVERRIDES.items():
        if brand_raw in name_lower:
            return cat

    # 2. Check explicit type mappings
    for t in types or []:
        if t in TYPE_TO_CATEGORY:
            return TYPE_TO_CATEGORY[t]

    # 3. Fuzzy match name to category list (fallback)
    matches = get_close_matches(place_name, CATEGORIES, n=1, cutoff=0.6)
    if matches:
        return matches[0]

    # 4. Default fallback
    return "Other purchases"

# -------------------------------------------------------------------
# Variant: return both brand-based and default categories
# -------------------------------------------------------------------
def map_place_to_categories(place_name: str, types: list[str]) -> tuple[str | None, str]:
    """
    Returns a tuple: (brand_category_or_None, default_category)
    - brand_category_or_None: category matched via BRAND_OVERRIDES (robust normalization)
    - default_category: category from types/fuzzy/default path (ignores brand overrides)
    """
    name_lower = (place_name or "").lower()
    name_norm = _normalize_text(place_name or "")

    # Brand category (robust normalization)
    brand_category = None
    for brand_norm, cat in _NORMALIZED_BRAND_OVERRIDES.items():
        if brand_norm and brand_norm in name_norm:
            brand_category = cat
            break
    if brand_category is None:
        for brand_raw, cat in BRAND_OVERRIDES.items():
            if brand_raw in name_lower:
                brand_category = cat
                break

    # Default path (ignore brand overrides; use types then fuzzy then fallback)
    if types:
        for t in types:
            if t in TYPE_TO_CATEGORY:
                return (brand_category, TYPE_TO_CATEGORY[t])
    matches = get_close_matches(place_name or "", CATEGORIES, n=1, cutoff=0.6)
    if matches:
        default_category = matches[0]
    else:
        default_category = "Other purchases"

    return (brand_category, default_category)

# -------------------------------------------------------------------
# Build search terms for ranking given a category and available columns
# -------------------------------------------------------------------
def build_search_terms(category: str, df_columns: list[str]) -> list[str]:
    """
    Build a compact list of search terms to match reward columns.
    Strategy:
      - include the category itself (exact text)
      - include any columns that already contain the category as a substring
      - include generic fallback terms like 'Everywhere'
    No brand/category synonyms are applied here to avoid cross-brand leakage.
    """
    terms: list[str] = []
    normalized = (category or "").strip()
    if normalized:
        terms.append(normalized)
        cat_lower = normalized.lower()
        for column in df_columns:
            if column == "Card Name":
                continue
            if cat_lower in column.lower():
                terms.append(column)
    # Add generic fallbacks
    terms.extend(DEFAULT_FALLBACK_TERMS)
    # Dedupe preserving order
    seen = set()
    out: list[str] = []
    for t in terms:
        tl = t.lower()
        if tl in seen:
            continue
        seen.add(tl)
        out.append(t)
    return out
# -------------------------------------------------------------------
# 5. Example test runs
# -------------------------------------------------------------------
if __name__ == "__main__":
    examples = [
        ("Target", ["department_store"]),
        ("Whole Foods Market", ["supermarket", "food", "point_of_interest"]),
        ("Starbucks", ["cafe", "restaurant"]),
        ("Shell Gas Station", ["gas_station"]),
        ("Hyatt Regency", ["lodging"]),
        ("AMC Theatres", ["movie_theater"]),
        ("Trader Joe's", ["supermarket"]),
        ("Some random gift shop", ["store"]),
        ("Marriott Marquis", ["lodging"]),
    ]


