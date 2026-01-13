# Next Steps: Migrating to Production CloudKit Environment

## Current Status

✅ **Completed:**
- Data export/import system implemented
- Enhanced iCloud sync monitoring with status indicators
- New "Data" tab in Settings with backup controls
- Manual sync trigger added
- Production entitlements file exists (`HardPhaseTracker-Production.entitlements`)

## Step 1: Export Your Current Data

1. **Build and run the app** (TestFlight or Xcode)
2. **Export your data:**
   - Open the app
   - Go to Settings (gear icon)
   - Tap on the new "Data" tab
   - In the "Backup & Restore" section, tap "Export all data"
   - Save the JSON file to iCloud Drive or Files app
   - The file will be named like `HardPhaseTracker_backup_2026-01-14_070300.json`
3. **Keep this backup safe** - you'll need it after switching environments

## Step 2: Switch to Production CloudKit Environment

You need to configure Xcode to use the production entitlements file for Release builds.

### Option A: Update in Xcode (Recommended)

1. Open `HardPhaseTracker.xcodeproj` in Xcode
2. Select the project in the navigator (top blue icon)
3. Select the "HardPhaseTracker" target
4. Go to "Build Settings" tab
5. Search for "Code Signing Entitlements"
6. For the "Release" configuration, change the value from:
   - Current: `HardPhaseTracker/Resources/HardPhaseTracker.entitlements`
   - New: `HardPhaseTracker/Resources/HardPhaseTracker-Production.entitlements`
7. Save the project

### What This Changes

**Development Entitlements** (current TestFlight):
- Uses `Development` CloudKit environment
- Separate database from production
- Good for testing, but doesn't sync with App Store builds

**Production Entitlements** (after change):
- Uses `Production` CloudKit environment
- Same database as App Store builds
- TestFlight and production will sync together
- Will NOT sync with development builds anymore

## Step 3: Build and Deploy

1. **Clean build** in Xcode (Product → Clean Build Folder)
2. **Archive** the app (Product → Archive)
3. **Upload to TestFlight**
4. Wait for processing
5. Install on your devices

## Step 4: Import Your Data

After installing the new TestFlight build:

1. Open the app on your primary device
2. Go to Settings → Data tab
3. Tap "Import data"
4. Select your backup JSON file
5. Confirm the import (this will replace all existing data)
6. Wait for import to complete

## Step 5: Verify Sync Between Devices

1. Install the same TestFlight build on your iPad
2. On iPhone: Go to Settings → Data → tap "Sync now"
3. On iPad: Go to Settings → Data → tap "Sync now"
4. Verify that data appears on both devices
5. Make a test change on one device
6. Sync both devices again
7. Verify the change appears on the other device

## Important Notes

⚠️ **Before switching:**
- Export your data from the current TestFlight build
- Keep the backup file safe
- You can export multiple times if needed

⚠️ **After switching:**
- Old TestFlight (development) data won't automatically migrate
- You must import your backup on the new build
- Development builds (Xcode) won't sync with TestFlight/Production anymore

⚠️ **For development:**
- Keep using development entitlements for local Xcode builds
- This keeps your test data separate from production
- You can always export/import between environments

## Troubleshooting

### Sync isn't working between devices
1. Check both devices are signed into iCloud
2. Check Settings → Data → iCloud Sync status
3. Try manual "Sync now" button
4. Check network connectivity
5. Wait a few minutes - CloudKit can take time to propagate

### Import fails
1. Check the JSON file isn't corrupted
2. Try exporting again from the old build
3. Check file permissions in Files app

### Lost data
- Don't panic! Your export file has everything
- Re-import the backup file
- If you exported multiple times, try the most recent backup

## Files Changed

- `HardPhaseTracker/Shared/Services/DataExportImportService.swift` - Export/import logic
- `HardPhaseTracker/Common/UI/SettingsView.swift` - New Data tab UI
- `HardPhaseTracker/Shared/SwiftData/CloudKitSyncService.swift` - Enhanced sync monitoring
- `HardPhaseTracker/Common/UI/ShareSheet.swift` - iOS share helper
- `HardPhaseTracker/Resources/HardPhaseTracker-Production.entitlements` - Production config (already exists)

## Questions?

If you encounter any issues, check:
1. Xcode build settings are correct
2. Both devices are on the same build version
3. iCloud is enabled and signed in
4. Network connectivity is working
5. CloudKit sync status in Settings → Data

---

**Created:** 2026-01-14  
**Commit:** 4db39c9 - feat: Add data export/import and enhanced iCloud sync monitoring
