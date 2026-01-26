# App Store Screenshots

This directory contains App Store-ready screenshots resized to Apple's exact requirements.

## Required Dimensions

### iPhone
- **Portrait:** 1284 × 2778 px (iPhone 12/13/14/15/16/17 Pro Max)
- **Landscape:** 2778 × 1284 px
- **Minimum:** 3 screenshots required
- **Maximum:** 10 screenshots allowed

### iPad Pro 13-inch
- **Portrait:** 2064 × 2752 px
- **Landscape:** 2752 × 2064 px
- **Minimum:** 3 screenshots required
- **Maximum:** 10 screenshots allowed

## Current Screenshots

### iPhone (6 screenshots) ✅
Location: `./iPhone/`

All screenshots resized from simulator captures (1320 × 2868) to App Store dimensions (1284 × 2778).

### iPad (7 screenshots) ✅
Location: `./iPad/`

All screenshots captured from iPad Pro 13-inch (M5) simulator at correct dimensions (2752 × 2064 landscape).

## How to Add/Update Screenshots

### Taking Screenshots in Simulator
1. Open iPhone 17 Pro Max or iPad Pro 13-inch (M4) simulator
2. Run HardPhaseTracker app
3. Set up desired app state (fasting schedules, meals, etc.)
4. Press `Cmd + S` to save screenshot (saves to Desktop)
5. Run resize script (see below)

### Resizing Screenshots

**iPhone screenshots (from 1320 × 2868 to 1284 × 2778):**
```bash
cd ~/Desktop
for file in "Simulator Screenshot - iPhone"*.png; do
  if [ -f "$file" ]; then
    timestamp=$(echo "$file" | sed 's/.*at //' | sed 's/.png//' | tr ' :.' '-')
    magick "$file" -resize 1284x2778! "./AppStore/Screenshots/iPhone/iPhone-${timestamp}.png"
  fi
done
```

**iPad screenshots (already correct dimensions from iPad Pro 13-inch M5 simulator):**
```bash
cd ~/Desktop
for file in "Simulator Screenshot - iPad"*.png; do
  if [ -f "$file" ]; then
    timestamp=$(echo "$file" | sed 's/.*at //' | sed 's/.png//' | tr ' :.' '-')
    output_file="/Users/gordonbeeming/Developer/github/gordonbeeming/HardPhaseTracker/AppStore/Screenshots/iPad/iPad-${timestamp}.png"
    
    # Check if resize needed (iPad Pro 13" M5 captures at correct 2752 × 2064)
    dimensions=$(file "$file" | grep -o "[0-9]* x [0-9]*")
    if [[ "$dimensions" == "2752 x 2064" ]] || [[ "$dimensions" == "2064 x 2752" ]]; then
      cp "$file" "$output_file"  # Already correct, just copy
    else
      magick "$file" -resize 2752x2064! "$output_file"  # Resize if needed
    fi
  fi
done
```

## Screenshot Recommendations (from docs/AppStoreSubmissionChecklist.md)

### iPhone Screenshots
1. Dashboard - Active Fasting (fasting timer, current phase)
2. Eating Window Schedule (schedule selector with 16/8, OMAD, etc.)
3. Meal Logging (meal template selection)
4. Weight Trends (7-day weight graph)
5. Fasting Phase Details (educational phase cards)

### iPad Screenshots
1. Dashboard - Full View (complete dashboard with all widgets)
2. Split View (two tabs side-by-side, if supported)
3. Settings/Analysis (larger screen experience)

### Appearance
**Use Dark Mode** for primary screenshots for better visual impact in the App Store.

## Notes
- ImageMagick (`magick` command) is required for resizing
- Screenshots are force-resized with `!` flag to exact dimensions
- Original simulator screenshots are not stored in this repo (Desktop only)
- Keep this directory in git for future App Store updates

## Last Updated
2026-01-24 - Initial iPhone (6) and iPad (7) screenshots added - All App Store ready! ✅
