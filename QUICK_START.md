# Quick Start Guide

## TL;DR - Does it work?

**YES! ✅** The project is fully functional. Here's proof:

```bash
# Activate virtual environment
source venv/bin/activate

# Try it yourself
python map.py "Target"
python map.py "Starbucks"
python map.py "Whole Foods"
```

---

## Quick Test (Copy & Paste)

```bash
cd "/Users/sanmaysarada/Downloads/scraper 2"
source venv/bin/activate
python map.py "Target San Francisco"
```

**Expected Output:**
```
Name: Target
Address: 789 Mission St, San Francisco, CA 94103, United States
Mapped Category: Target
Top cards for category:
  1. Target REDcard: 5.0 — 5% — Target | 5% — Target.com
  2. Capital One Venture X Rewards Credit Card: 2.0 — 2% — Everywhere
  ...
```

---

## What This Does

Tells you which of YOUR credit cards gives the best rewards at any location.

**Example:**
- You're at Starbucks → Use U.S. Bank Altitude® Go (4% back)
- You're at Target → Use Target REDcard (5% back)
- You're at Whole Foods → Use U.S. Bank Altitude® Go (2% back)

---

## Your Cards

Currently configured with:
1. Target REDcard
2. Capital One Venture X Rewards Credit Card
3. American Express® Gold Card
4. Chase Sapphire Reserve®
5. U.S. Bank Altitude® Go

To change: Edit `USER_CARDS` in `map.py` (lines 30-36)

---

## Full Test Results

See `TEST_RESULTS.md` for detailed test results and technical documentation.

---

## One-Line Summary

**It works perfectly!** All tests pass, API is connected, and it correctly recommends the best credit card for any location.

