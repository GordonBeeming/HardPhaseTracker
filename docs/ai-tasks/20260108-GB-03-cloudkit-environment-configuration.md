# CloudKit Environment Configuration

**Date:** 2026-01-08  
**Author:** GB (Gordon Beeming)  
**Task:** Configure different CloudKit environments for local development vs CI/CD builds

## Overview

Implemented environment-specific entitlements to use Development CloudKit when building locally in Xcode, and Production CloudKit when building through GitHub Actions.

## Problem

- TestFlight builds weren't syncing data between devices
- Root cause: Development CloudKit environment doesn't sync reliably in TestFlight
- Need Production CloudKit for TestFlight/App Store builds
- Want to keep Development CloudKit for local development (easier to reset/debug)

## Solution

Created two entitlements files with different CloudKit environments:

### 1. Development Entitlements (Local Xcode)
**File:** `HardPhaseTracker/Resources/HardPhaseTracker.entitlements`
- CloudKit: **Development**
- Push Notifications: **development**
- Used when: Building/running from Xcode locally

### 2. Production Entitlements (CI/CD)
**File:** `HardPhaseTracker/Resources/HardPhaseTracker-Production.entitlements`
- CloudKit: **Production**
- Push Notifications: **production**
- Used when: Building through GitHub Actions (TestFlight + App Store)

## Implementation

### Created Production Entitlements File

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>production</string>
	<key>com.apple.developer.aps-environment</key>
	<string>production</string>
	<key>com.apple.developer.healthkit</key>
	<true/>
	<key>com.apple.developer.icloud-container-environment</key>
	<string>Production</string>
	<key>com.apple.developer.icloud-container-identifiers</key>
	<array>
		<string>iCloud.com.gordonbeeming.HardPhaseTracker</string>
	</array>
	<key>com.apple.developer.icloud-services</key>
	<array>
		<string>CloudKit</string>
	</array>
</dict>
</plist>
```

### Updated GitHub Actions Workflows

Modified `.github/workflows/deploy.yml` to specify production entitlements:

**Beta (TestFlight) build:**
```yaml
- name: Archive app
  run: |
    xcodebuild archive \
      ...
      CODE_SIGN_ENTITLEMENTS="HardPhaseTracker/Resources/HardPhaseTracker-Production.entitlements"
```

**Production (App Store) build:**
```yaml
- name: Archive app
  run: |
    xcodebuild archive \
      ...
      CODE_SIGN_ENTITLEMENTS="HardPhaseTracker/Resources/HardPhaseTracker-Production.entitlements"
```

## How It Works

### Local Development (Xcode)
1. Developer opens project in Xcode
2. Xcode uses `HardPhaseTracker.entitlements` by default
3. App connects to **Development** CloudKit
4. Data is isolated to development environment
5. Easy to reset/debug without affecting production data

### CI/CD (GitHub Actions)
1. Code pushed to `main` branch
2. GitHub Actions workflow triggers
3. Build command explicitly sets `CODE_SIGN_ENTITLEMENTS` to production file
4. App connects to **Production** CloudKit
5. TestFlight builds can sync between devices
6. App Store builds use production data

## Benefits

✅ **Development:**
- Can test CloudKit without affecting production
- Easy to reset development data
- Isolated testing environment

✅ **TestFlight:**
- Uses Production CloudKit
- Data syncs between devices
- Realistic testing environment for beta testers

✅ **App Store:**
- Uses Production CloudKit
- Proper data sync for end users
- Persistent, production-grade storage

## Testing After Next Deploy

🚨🚨🚨 **Action required after next GitHub deployment:**

1. **Install fresh TestFlight build** on both devices
   - Or uninstall current TestFlight version first
   - This ensures clean Production CloudKit setup

2. **Verify same iCloud account** on both devices
   - Settings → [Your Name] → check Apple ID
   - Both must be signed in to same account

3. **Test sync:**
   - Create eating window schedule on iPhone
   - Wait ~5 minutes
   - Open app on iPad → verify schedule appears
   - Add meal template on iPad
   - Wait ~5 minutes
   - Check iPhone → verify template appears

4. **Common sync delays:**
   - Initial sync: 5-30 minutes
   - Subsequent changes: 1-5 minutes
   - Requires good internet connection on both devices
   - Both devices must have iCloud Drive enabled

## Troubleshooting

### Data not syncing?
1. Check both devices use **same Apple ID**
2. Verify iCloud Drive is enabled on both
3. Check internet connection on both devices
4. Give it time (initial sync can take 30+ minutes)
5. Try force-quitting and reopening the app

### Development environment issues?
- Development data is separate from production
- Safe to delete and recreate development data
- Won't affect TestFlight or App Store users

### Need to reset Production CloudKit?
⚠️ **WARNING:** This affects all users!
- Only do this before public launch
- Use CloudKit Dashboard to manage schema
- Consider migration strategies for production data

## Files Modified

- `HardPhaseTracker/Resources/HardPhaseTracker-Production.entitlements` (new)
- `.github/workflows/deploy.yml` (both beta and production jobs)

## Related Documentation

- Apple CloudKit Documentation: https://developer.apple.com/icloud/cloudkit/
- SwiftData with CloudKit: https://developer.apple.com/documentation/swiftdata/syncing-data-with-cloudkit
