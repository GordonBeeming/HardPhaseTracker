# CloudKit Proactive Sync on App Launch

**Date:** 2026-01-08  
**Author:** GB (Gordon Beeming)  
**Task:** Add proactive CloudKit sync on app launch and foreground

## Overview

Implemented proactive CloudKit sync to reduce data sync delays when users switch between devices.

## Problem

SwiftData with CloudKit syncs automatically in the background, but timing is unpredictable:
- Sync can be delayed by iOS power management
- Users may not see recent changes from other devices immediately
- No way to "force" sync from SwiftData (it manages CloudKit internally)

## Solution

Created `CloudKitSyncService` that encourages SwiftData to sync by:

1. **Triggering save operations** - Even empty saves trigger CloudKit push
2. **Fetching data** - Forces SwiftData to check for remote changes (pull)
3. **Network monitoring** - Only attempts sync when online
4. **Rate limiting** - Prevents excessive sync attempts (max every 5 minutes)
5. **App lifecycle hooks** - Syncs on launch and foreground

## Implementation

### CloudKitSyncService

New file: `HardPhaseTracker/Shared/SwiftData/CloudKitSyncService.swift`

**Key features:**
- `@MainActor` for thread safety
- Network status monitoring via `NWPathMonitor`
- Tracks last sync attempt to avoid spam
- Logs all sync activity for debugging

**Public API:**
```swift
// Request sync now (if online)
func requestSync(modelContext: ModelContext)

// Request sync only if stale (> 5 min since last)
func requestSyncIfStale(modelContext: ModelContext, staleAfterMinutes: Double = 5)

// Observable properties
@Published private(set) var lastSyncAttempt: Date?
@Published private(set) var isOnline: Bool
```

**How it works:**
```swift
func requestSync(modelContext: ModelContext) {
    guard isOnline else { return }
    
    // 1. Save (even if nothing changed) → triggers CloudKit push
    try modelContext.save()
    
    // 2. Fetch small data → triggers CloudKit pull
    _ = try? modelContext.fetch(FetchDescriptor<AppSettings>(fetchLimit: 1))
    
    // 3. Record attempt
    lastSyncAttempt = Date()
}
```

### ContentView Integration

Modified `ContentView.swift` to use the service:

```swift
@StateObject private var cloudKitSync = CloudKitSyncService()

.task {
    SeedSchedulesService.seedIfNeeded(modelContext: modelContext)
    
    // Request CloudKit sync on app launch
    cloudKitSync.requestSyncIfStale(modelContext: modelContext)
}
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
    // Also sync when app comes back to foreground
    cloudKitSync.requestSyncIfStale(modelContext: modelContext)
}
```

## Sync Triggers

The app now requests CloudKit sync at these times:

1. **App Launch** (cold start)
2. **App Foreground** (switching back to app)
3. **Rate Limited** - Max once per 5 minutes
4. **Online Only** - Skips when offline

## Benefits

✅ **More predictable sync** - Encourages sync at logical times
✅ **Better UX** - Users see updates sooner when switching devices
✅ **Battery efficient** - Rate limiting prevents excessive operations
✅ **Network aware** - Doesn't attempt sync when offline
✅ **Observable** - Can show sync status in UI if needed
✅ **Non-breaking** - Doesn't interfere with SwiftData's automatic sync

## Limitations

⚠️ **Not a true "force sync"** - SwiftData still controls actual sync timing
⚠️ **Best effort** - iOS may delay sync for power management
⚠️ **Network dependent** - Requires good internet connection
⚠️ **Rate limited** - Won't sync more than every 5 minutes

## Important Notes

### This is NOT a workaround for:
- Poor internet connection
- iCloud account issues
- CloudKit quota limits
- Development vs Production environment mismatches

### This DOES help with:
- Reducing perceived sync delay
- Encouraging sync at app transitions
- Making sync more predictable for users

## Testing

**Test scenarios:**
1. **Device A** → Create meal template
2. **Device A** → Force quit app
3. **Device B** → Launch app (should trigger sync)
4. **Device B** → Wait ~30 seconds to 2 minutes
5. **Device B** → Meal template should appear

**Before this change:** Could take 5-30 minutes  
**After this change:** Should be 1-5 minutes (best case)

**Note:** Initial sync (first time device connects) may still take longer.

## Logging

All sync activity is logged to Console.app:

```
subsystem: HardPhaseTracker
category: CloudKitSync
```

**Example logs:**
```
Requesting CloudKit sync...
Sync request completed
Sync recent (< 5 min ago), skipping
Network came online
Network went offline
```

## Future Enhancements

Possible improvements:
1. Show sync status indicator in UI
2. Manual "Pull to Refresh" gesture on views
3. Sync when specific views appear (e.g., Meals list)
4. Exponential backoff for sync failures
5. Sync immediately when network reconnects (after offline period)

## Files Modified

- `ContentView.swift` - Added CloudKitSyncService integration

## Files Created

- `CloudKitSyncService.swift` - New sync helper service

## Related Documentation

- Apple CloudKit Best Practices: https://developer.apple.com/documentation/cloudkit/managing_icloud_containers_with_the_cloudkit_database_app
- SwiftData Sync: https://developer.apple.com/documentation/swiftdata/syncing-data-with-cloudkit
