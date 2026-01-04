# GitHub Actions CI/CD Setup

This repository uses GitHub Actions for automated testing and deployment to TestFlight (beta) and App Store (production).

## Deployment Flow

```
Push to main → Build & Test → Deploy to Beta (TestFlight)
                                      ↓
                              Test in TestFlight
                                      ↓
                           Merge main to production
                                      ↓
                Build & Test → Deploy to Production (App Store)
                                      ↓ (optional: requires approval)
```

## Workflows

### 1. PR Verification
- **Trigger:** Pull requests to `main`
- **Actions:** Build and run all tests
- **Purpose:** Ensure code quality before merge

### 2. Deploy
- **Triggers:** 
  - Push to `main` → Deploy to beta
  - Push to `prod` → Deploy to production
- **Actions:** Build, test, sign, archive, upload to App Store Connect

## Setup Instructions

### Step 1: GitHub Environments (Already Created ✓)

You've created `beta` and `prod` environments in GitHub.

### Step 2: Get Apple Certificates & Keys

#### Code Signing Certificate
1. Open **Keychain Access** on Mac
2. Find your **Apple Distribution** certificate
3. Right-click → Export → Save as `.p12` file with password
4. Convert to base64:
   ```bash
   base64 -i Certificates.p12 | pbcopy
   ```

#### Provisioning Profile
1. Download from [Apple Developer Portal](https://developer.apple.com/account/resources/profiles/)
2. Convert to base64:
   ```bash
   base64 -i YourProfile.mobileprovision | pbcopy
   ```

#### App Store Connect API Key
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Users and Access → Keys → App Store Connect API
3. Click **+** → Create key with **Developer** access
4. Download the `.p8` file (only downloadable once!)
5. Note the **Key ID** and **Issuer ID**
6. Copy file contents:
   ```bash
   cat AuthKey_ABC123.p8 | pbcopy
   ```

### Step 3: Add Secrets to Both Environments

Go to repo → Settings → Environments → Select environment → Add secret

Add these **9 secrets** to **BOTH** `beta` and `prod` environments:

| Secret Name | Value |
|------------|-------|
| `CERTIFICATES_P12` | Base64-encoded `.p12` file |
| `CERTIFICATES_PASSWORD` | Password for `.p12` |
| `PROVISIONING_PROFILE` | Base64-encoded `.mobileprovision` |
| `PROVISIONING_PROFILE_NAME` | Name in Xcode (e.g., "HardPhase Tracker AppStore") |
| `CODE_SIGN_IDENTITY` | e.g., `"Apple Distribution: Your Name (TEAM123)"` |
| `APPLE_TEAM_ID` | 10-character Team ID |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID from App Store Connect |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID (UUID format) |
| `APP_STORE_CONNECT_API_KEY` | Contents of `.p8` file |

### Step 4: Add Production Approver (After Repo is Public)

1. Go to Settings → Environments → `prod`
2. Check "Required reviewers"
3. Add yourself or team members
4. Save protection rules

Now production deployments will wait for approval before running.

## Usage

### Deploy to TestFlight

```bash
git checkout main
git add .
git commit -m "New feature"
git push origin main
```

Automatically deploys to TestFlight for testing.

### Deploy to App Store

After testing in TestFlight:

```bash
git checkout production
git merge main
git push origin production
```

If you've added required reviewers, they must approve the deployment. Then go to App Store Connect to submit for review.

### Creating Pull Requests

```bash
git checkout -b feature/my-feature
# ... make changes ...
git push origin feature/my-feature
```

Create PR on GitHub → Tests run automatically

## Build Numbers & Versioning

- **Build number:** Automatically set to GitHub run number
- **Version number:** Update manually in `HardPhaseTracker/Resources/Info.plist`

Example workflow:
```bash
# Update version to 1.1
# Edit Info.plist: CFBundleShortVersionString = "1.1"

git add HardPhaseTracker/Resources/Info.plist
git commit -m "Bump version to 1.1"
git push origin main
# → Build 42 (auto) for version 1.1
```

## Artifacts

All workflows upload artifacts:
- **Test Results:** XCResult bundles (30 days)
- **IPA Files:** Signed app packages (90 days)

Download from Actions tab in GitHub.

## Troubleshooting

### "No signing certificate"
- Verify `CERTIFICATES_P12` is correctly base64-encoded
- Check `CERTIFICATES_PASSWORD` matches
- Ensure certificate hasn't expired

### "Profile doesn't match"
- Verify `PROVISIONING_PROFILE_NAME` exactly matches Xcode
- Check bundle ID matches profile
- Ensure profile hasn't expired

### Upload fails
- Verify all App Store Connect API secrets are correct
- Check API key has Developer role
- Ensure app exists in App Store Connect

### Tests fail on CI but pass locally
- Workflows use Xcode 15.2
- Check simulator: iPhone 15 Pro, iOS 17.2
- Download test artifacts for logs

## Manual Trigger

All workflows support manual runs:
1. Go to Actions tab
2. Select workflow
3. Click "Run workflow"
4. Choose branch and environment (if applicable)

## Cost Estimate

- macOS runners: ~$0.08/minute
- Average deployment: 20-30 minutes
- ~$1.60-$2.40 per deployment
