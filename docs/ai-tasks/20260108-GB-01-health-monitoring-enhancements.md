# Health Monitoring Enhancements

**Date:** 2026-01-08  
**Author:** GB (Gordon Beeming)  
**Task:** Implement health monitoring improvements for TestFlight issues and feature requests

## Overview

This document summarizes the changes made to address four key issues related to health monitoring in the HardPhaseTracker app.

## Issues Addressed

### Issue 1: System Schedules Missing on First Launch (TestFlight)

**Problem:** Users installing via TestFlight reported no eating window schedules appearing on first launch, despite working in simulator.

**Solution:** Modified `SeedSchedulesService` to check and re-insert system schedules on every app startup instead of relying on a one-time seed flag.

**Changes:**
- Removed `didSeedSchedules_v1` UserDefaults flag
- System schedules (16/8, 18/6, 20/4, OMAD) are now verified on every app launch
- Schedules are marked as `isBuiltIn = true` to prevent user deletion
- First launch date is recorded for health monitoring start date

### Issue 2: Weight Chart Y-Axis Starts at 0 (Flat Appearance)

**Problem:** Dashboard weight chart appears flat because Y-axis ranges from 0 to max weight, compressing the visual differences.

**Solution:** 
- Added weight goal setting in app settings
- Implemented dynamic Y-axis bounds calculation
- Chart now shows 14 days of data instead of 7
- Y-axis lower bound is calculated as the highest of:
  - (Goal weight - 5) OR
  - (Oldest weight in view - 20)

**Changes:**
- Added `weightGoalKg` field to `AppSettings`
- Modified `DashboardView` to use `weightsLast14Days` and apply `.chartYScale(domain:)`
- Added weight goal input in Settings → Health
- Weight goal supports both metric (kg) and imperial (lb) with automatic conversion

### Issue 3: Health Monitoring Start Date and Configurable Data Pull Range

**Problem:** App pulls all available health data regardless of when user started their journey, and data pull range was hardcoded.

**Solution:**
- Added `healthMonitoringStartDate` setting (defaults to first app launch)
- Added `healthDataMaxPullDays` setting with options: 30, 60, 90, 180, 365 days
- Default is 90 days
- HealthKit queries now respect both the start date and max pull range

**Changes:**
- Added `healthMonitoringStartDate` and `healthDataMaxPullDays` to `AppSettings`
- Modified `HealthKitService.fetchWeightSamples()` to accept `startDate` parameter
- Added `HealthKitService.fetchFirstWeight()` to get starting weight
- Updated `HealthKitViewModel` to pass these parameters to all refresh calls
- Added settings UI in Settings → Health → Health monitoring

### Issue 4: Dashboard Weight Loss Display

**Problem:** Dashboard should show weight lost and duration without explicitly showing starting weight.

**Solution:** 
- Added display of weight lost with smart duration formatting
- Shows "Lost X kg/lb in Y duration" where duration intelligently formats as days/weeks/months/years

**Changes:**
- Modified `DashboardWeightTrendCardView` to show weight loss info
- Added `formatDuration()` helper that smartly formats time spans:
  - < 7 days: "X days"
  - < 30 days: "X weeks"
  - < 365 days: "X months"
  - >= 365 days: "X years" or "Xy Ym" for mixed display

## Technical Details

### Modified Files

1. **AppSettings.swift**
   - Added: `weightGoalKg`, `healthMonitoringStartDate`, `healthDataMaxPullDays`
   - All fields optional for migration safety

2. **SeedSchedulesService.swift**
   - Refactored to always check system schedules
   - Records first launch date for health monitoring
   - Backfills health monitoring settings for existing users

3. **HealthKitService.swift**
   - Updated `fetchWeightSamples()` to accept `lastDays` and `startDate` parameters
   - Added `fetchFirstWeight()` to get journey starting weight
   - Query respects both monitoring start date and max pull days

4. **HealthKitViewModel.swift**
   - Added `weightsLast14Days` and `firstWeight` published properties
   - Updated `refresh()` and `refreshIfCacheStale()` to accept `maxDays` and `startDate`
   - Cache now includes 14-day weights and first weight

5. **DashboardView.swift**
   - Updated to pass health settings to refresh calls
   - Modified `DashboardWeightTrendCardView` to:
     - Display 14 days of data
     - Calculate dynamic Y-axis bounds
     - Show weight lost with duration
     - Accept `weightGoalKg` parameter

6. **SettingsView.swift**
   - Added Health → Weight goal section
   - Added Health → Health monitoring section
   - Weight goal handles unit conversion (kg ↔ lb)
   - Updated refresh call to use new parameters

### Migration Safety

All changes are backwards-compatible and don't require app reinstallation:

**AppSettings Fields:**
- All new fields are optional (`?`) for safe migration
- `weightGoalKg?: Double?` - nil means not set
- `healthMonitoringStartDate?: Date?` - backfilled to first launch date or today
- `healthDataMaxPullDays?: Int?` - defaults to 90 days
- Backfill happens automatically in `SeedSchedulesService` on next app launch

**HealthKit Cache:**
- Cache version bumped from v1 → v2
- Old v1 cache automatically detected and migrated
- Missing fields in migrated cache trigger automatic refresh
- No data loss during migration

**System Schedules:**
- Checked and re-inserted on every app startup
- Existing users get missing schedules added automatically
- No impact on user's custom schedules

### Data Flow

1. **App Startup:**
   - `ContentView.task` → `SeedSchedulesService.seedIfNeeded()`
   - System schedules verified/inserted
   - Health monitoring settings initialized

2. **Dashboard Load:**
   - Reads `healthMonitoringStartDate` and `healthDataMaxPullDays` from `AppSettings`
   - Passes to `HealthKitViewModel.refreshIfCacheStale()`
   - HealthKit queries filtered by both parameters

3. **Settings Changes:**
   - Weight goal, start date, or max days changes trigger save
   - Next dashboard refresh uses updated parameters
   - Cache invalidated on significant changes

## Testing Notes

🚨🚨🚨 **No app reinstall needed!**

The migration is handled automatically:

### Migration Strategy

1. **HealthKit Cache Migration:**
   - Old cache (v1) automatically migrated to new format (v2)
   - Missing fields (`weightsLast14Days`, `firstWeight`) trigger automatic refresh on next dashboard load
   - Old cache cleaned up after migration

2. **AppSettings Migration:**
   - All new fields are optional and have safe defaults
   - Existing installs get backfilled values in `SeedSchedulesService`
   - No data loss or app reinstall required

3. **System Schedules:**
   - Checked and re-inserted on every app startup
   - Existing users get missing schedules added automatically

### Test Checklist:
- [ ] **Upgrade test:** Install current version, then update → verify smooth transition
- [ ] **Fresh install:** Verify all 4 system schedules appear
- [ ] Set weight goal in Settings → verify chart Y-axis adjusts
- [ ] Change journey start date → verify older data doesn't appear
- [ ] Change max pull days → verify data range respected
- [ ] Weight loss shows when first & latest weight available
- [ ] Unit system toggle (kg ↔ lb) converts weight goal properly
- [ ] Chart shows 14 days of data

## Future Considerations

1. Consider adding visual indicator of weight goal on chart (e.g., dashed line)
2. Consider adding weight trend indicators (up/down arrows, rates)
3. Consider adding weight prediction based on current trajectory
4. Consider allowing users to set custom chart date ranges

## Related Files

- `HardPhaseTracker/Common/Domain/AppSettings.swift`
- `HardPhaseTracker/Features/Schedule/SeedSchedulesService.swift`
- `HardPhaseTracker/Features/HealthKit/HealthKitService.swift`
- `HardPhaseTracker/Features/HealthKit/HealthKitViewModel.swift`
- `HardPhaseTracker/Features/Dashboard/DashboardView.swift`
- `HardPhaseTracker/Common/UI/SettingsView.swift`

## Build Fixes

### Issue: Missing Foundation import
**Error:** Cannot find type 'Date' in scope  
**File:** AppSettings.swift  
**Fix:** Added `import Foundation` at the top of the file

### Issue: Extra arguments in AppSettings init
**Error:** Extra arguments at positions #1, #2, #3 in call  
**File:** SeedSchedulesService.swift line 18  
**Fix:** Changed from passing parameters to init to creating instance with defaults and setting properties:
```swift
// Before (error)
modelContext.insert(AppSettings(
    selectedSchedule: nil,
    healthMonitoringStartDate: firstLaunchDate,
    healthDataMaxPullDays: 90
))

// After (fixed)
let settings = AppSettings()
settings.healthMonitoringStartDate = firstLaunchDate
settings.healthDataMaxPullDays = 90
modelContext.insert(settings)
```

Both issues resolved. Build should now succeed.
