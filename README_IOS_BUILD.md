# iOS IPA Build with GitHub Actions

## Setup Instructions

### 1. Push to GitHub
```bash
git init
git add .
git commit -m "Initial commit with iOS build workflow"
git branch -M main
git remote add origin https://github.com/yourusername/myqr.git
git push -u origin main
```

### 2. Configure iOS Signing (Required for distribution)

#### Option A: Development Team (Free)
1. Get Apple Developer account (free)
2. Create Team ID in Apple Developer portal
3. Update `ios/ExportOptions.plist`:
   - Replace `YOUR_TEAM_ID` with your actual Team ID
   - Update bundle identifier: `com.yourname.myqr`

#### Option B: Paid Developer Program ($99/year)
1. Enroll in Apple Developer Program
2. Create App ID and provisioning profiles
3. Add certificates and profiles to GitHub Secrets

### 3. GitHub Secrets Setup
Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:
- `APPLE_ID`: Your Apple Developer email
- `APPLE_PASSWORD`: App-specific password
- `TEAM_ID`: Your Apple Team ID

### 4. Build Process
The workflow will:
1. Trigger on push to main branch or manual dispatch
2. Use macOS runner with Xcode
3. Build Flutter iOS app
4. Create IPA archive
5. Upload IPA as GitHub artifact

### 5. Download IPA
After build completes:
1. Go to Actions tab in your GitHub repo
2. Click on the workflow run
3. Download `ios-ipa` artifact

## Manual Build Trigger
You can also trigger builds manually:
1. Go to Actions → Build iOS IPA
2. Click "Run workflow"
3. Set build number if needed

## Troubleshooting

### Common Issues:
1. **Signing errors**: Ensure Team ID and bundle identifier are correct
2. **Build failures**: Check that Flutter version is compatible
3. **Missing dependencies**: Verify all pods are installed correctly

### Debug Tips:
- Check workflow logs for detailed error messages
- Ensure iOS project configuration is valid
- Verify all required permissions are set in Info.plist

## Bundle Identifier
Current: `$(PRODUCT_BUNDLE_IDENTIFIER)` in `ios/Runner/Info.plist`
Update to your unique identifier: `com.yourname.myqr`

## Version Management
- Version: Set in `pubspec.yaml` (currently 1.0.0+1)
- Build number: Can be set manually when triggering workflow
