# App Store Submission Checklist

## Screenshots Required

### iPhone 6.7" (Pro Max) - REQUIRED
At least 3, up to 10 screenshots needed:

1. **Dashboard - Active Fasting** - Show the fasting timer, current phase, and "You're Fasting" state
2. **Eating Window Schedule** - Display the schedule selector with various options (16/8, OMAD, etc.)
3. **Meal Logging** - Show the meal template selection or meal logging interface
4. **Weight Trends** - Display the 7-day weight graph from Apple Health integration
5. **Fasting Phase Details** - Show one of the educational phase cards (e.g., Ketosis or Autophagy phase)

### iPad Pro 12.9" (3rd gen) - REQUIRED
At least 3, up to 10 screenshots needed:

1. **Dashboard - Full View** - Show the complete dashboard with all widgets
2. **Split View** (if supported) - Show two tabs side-by-side
3. **Settings/Analysis** - Show the larger screen experience

### Optional but Recommended
- iPhone 6.5" (older Pro Max models)
- iPhone 5.5" (older Plus models)
- iPad Pro 11"

### Screenshot Appearance Recommendation

**Use Dark Mode for Primary Screenshots**

Dark mode is strongly recommended for your App Store screenshots because:

1. **Better Visual Impact** - Dark mode screenshots stand out more in the App Store (which has a light background). The contrast makes your app look more premium and modern.

2. **Highlights Your Content** - For a fasting tracker, dark mode helps key information (timers, numbers, phase indicators) pop more against the dark background. Colorful elements (phase cards, graphs) appear more vibrant.

3. **Health & Wellness Aesthetic** - Dark mode conveys a focused, calm, meditative feel that aligns perfectly with fasting/wellness apps. It suggests sophistication and mindfulness.

4. **iOS Trends** - Most popular health/fitness apps showcase dark mode in their App Store listings because it photographs better.

5. **Hides UI Chrome** - Dark mode makes system UI elements less prominent, keeping focus on your app's content.

**Strategy:**
- Use dark mode for your first 3-4 screenshots (the most important ones that users see first)
- Optionally include 1-2 light mode screenshots later in the sequence to demonstrate both modes are supported
- If choosing just one aesthetic: **Dark Mode all the way**

## Critical Items (Blocking Submission)

### 1. Privacy Policy URL
- **Current URL**: https://gordonbeeming.com/hardphasetracker/privacy-policy
- **Status**: Returns 404 - needs to be published
- **Must Include**:
  - Local data storage with SwiftData
  - Apple Health read-only access (weight, body fat %, sleep)
  - iCloud CloudKit sync
  - No third-party analytics or tracking
  - User data rights (deletion, export)

### 2. App Store Connect Setup
- Create the app listing in App Store Connect
- Configure App Store Connect API credentials
- Upload app binary

### 3. GitHub Actions Secrets
Configure 9 secrets in both `beta` and `prod` environments:
- `CERTIFICATES_P12`
- `CERTIFICATES_PASSWORD`
- `PROVISIONING_PROFILE`
- `PROVISIONING_PROFILE_NAME`
- `CODE_SIGN_IDENTITY`
- `APPLE_TEAM_ID`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY`

### 4. Provisioning & Certificates
- Distribution certificate and provisioning profile
- App Store Connect API keys

## Recommended Before Submission

### Testing Checklist
- [ ] TestFlight beta testing with small group
- [ ] Test on physical iPhone (multiple screen sizes if possible)
- [ ] Test on physical iPad (portrait and landscape)
- [ ] Verify Apple Health integration works correctly
- [ ] Test iCloud sync between two devices
- [ ] Verify all fasting schedules work as expected
- [ ] Test meal logging and template creation
- [ ] Ensure dark mode works properly
- [ ] Test timezone handling for meal logs
- [ ] Verify all navigation and transitions
- [ ] Test edge cases (no meals logged, no health data, etc.)

## Nice to Have

### Optional Enhancements
- **App Preview Videos** - 15-30 second videos showing key features
- **Promotional Text** - 170 character highlight (can update without review)
- **What's New Text** - For version 1.0, describe the initial release

## Pre-Submission Review Notes

### For App Store Reviewers
- No login/authentication required
- Uses Apple Health read-only access
- Data stored locally with SwiftData
- iCloud sync available but optional
- All health information is educational only, not medical advice
- App includes comprehensive medical disclaimers about fasting

### Key Features to Highlight
- Minimalist fasting tracker for intermittent fasting
- Customizable eating window schedules (16/8, 18/6, 20/4, OMAD, 5:2, ADF, custom)
- Reusable meal templates
- Educational fasting phase information (7 phases: Fed State → Maximum Autophagy)
- Apple Health integration for weight trends
- Electrolyte tracking
- iCloud sync across devices

## Current Status

### Completed
- [x] App icons (all sizes)
- [x] App Store metadata (see `docs/AppStoreMetadata.md`)
- [x] Privacy strings in Info.plist
- [x] Deployment pipeline configuration
- [x] Version display in app
- [x] CloudKit configuration
- [x] Unit tests
- [x] Medical disclaimers in app

### In Progress
- [ ] Screenshots
- [ ] Privacy policy URL
- [ ] App Store Connect setup
- [ ] Certificates and provisioning
- [ ] Physical device testing

## Next Steps

1. Build the app and test on physical device
2. Take screenshots on required device sizes
3. Publish privacy policy to your website
4. Set up certificates and provisioning profiles
5. Configure GitHub Actions secrets
6. Create app listing in App Store Connect
7. Upload build via Xcode or automated pipeline
8. Add screenshots and metadata to App Store Connect
9. Submit for review

## Resources

- **Metadata**: See `docs/AppStoreMetadata.md` for complete copy
- **App Store Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **Screenshot Specifications**: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications
- **Privacy Policy Generator**: https://www.freeprivacypolicy.com/ or https://app-privacy-policy-generator.firebaseapp.com/

## Notes

- App version: 1.0 (Build 1)
- Minimum iOS: 18.0
- Bundle ID: com.gordonbeeming.HardPhaseTracker
- License: FSL-1.1-MIT (verify compatibility with App Store)
- Current readiness: **95%** - mainly missing screenshots and privacy policy
