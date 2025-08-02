# App Store Connect Setup for Fastlane Deliver

This guide will help you set up automated App Store deployment using Fastlane Deliver.

## Prerequisites

1. **Apple Developer Account** - You need a paid Apple Developer Program membership
2. **App Store Connect Access** - Your app should be created in App Store Connect
3. **Certificates & Provisioning** - Distribution certificate and App Store provisioning profile

## Setup Options

You have two main options for authentication:

### Option 1: Apple ID + App-Specific Password (Recommended for individuals)

1. **Set your Apple ID in Appfile:**
   ```ruby
   apple_id("your.email@example.com")
   ```

2. **Create App-Specific Password:**
   - Go to [appleid.apple.com](https://appleid.apple.com)
   - Sign in and go to "App-Specific Passwords"
   - Generate a new password for "Fastlane"
   - Store it securely

3. **Set environment variable:**
   ```bash
   export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="your-app-specific-password"
   ```

### Option 2: App Store Connect API Key (Recommended for teams/CI)

1. **Create API Key:**
   - Go to App Store Connect → Users and Access → Keys
   - Create a new API key with "App Manager" role
   - Download the `.p8` file

2. **Set environment variables:**
   ```bash
   export APP_STORE_CONNECT_API_KEY_ID="your-key-id"
   export APP_STORE_CONNECT_ISSUER_ID="your-issuer-id"
   export APP_STORE_CONNECT_API_KEY_PATH="/path/to/AuthKey_XXXXX.p8"
   ```

3. **Alternative: Place key file in fastlane directory:**
   - Put the `.p8` file in `fastlane/` directory
   - Fastlane will automatically detect it

## Environment Variables Setup

Create a `.env` file in the `fastlane/` directory (not committed to git):

```bash
# Option 1: Apple ID Authentication
FASTLANE_USER="your.email@example.com"
FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="your-app-specific-password"

# Option 2: API Key Authentication
APP_STORE_CONNECT_API_KEY_ID="your-key-id"
APP_STORE_CONNECT_ISSUER_ID="your-issuer-id" 
APP_STORE_CONNECT_API_KEY_PATH="./AuthKey_XXXXX.p8"

# Optional: Skip 2FA prompts
FASTLANE_SKIP_2FA_UPGRADE="true"
```

## Required App Store Information

Before using deliver, ensure your app has these configured in App Store Connect:

1. **App Information:**
   - App name and bundle ID
   - Primary and secondary categories
   - Content rights and age rating

2. **Pricing and Availability:**
   - Price tier (free or paid)
   - Availability in countries/regions

3. **App Privacy:**
   - Privacy policy URL
   - Data collection practices

## Available Fastlane Commands

### Basic Deployment
```bash
# Upload binary, metadata, and screenshots (no submission)
bundle exec fastlane ios deploy

# Submit already uploaded build for review
bundle exec fastlane ios submit

# Complete pipeline: build, upload, and submit for review
bundle exec fastlane ios deploy_and_submit
```

### Metadata Management
```bash
# Upload only metadata and screenshots (no binary)
bundle exec fastlane ios metadata_only

# Upload only screenshots
bundle exec fastlane ios screenshots_only

# Generate screenshots
bundle exec fastlane ios screenshots
```

### Legacy Commands (still available)
```bash
# Upload to TestFlight
bundle exec fastlane ios beta

# Basic App Store upload
bundle exec fastlane ios release
```

## Metadata Files

All App Store metadata is stored in `fastlane/metadata/en-US/`:

- `name.txt` - App name
- `subtitle.txt` - App subtitle  
- `description.txt` - App description
- `keywords.txt` - Comma-separated keywords
- `promotional_text.txt` - Promotional text
- `release_notes.txt` - What's new in this version
- `marketing_url.txt` - Marketing website URL
- `privacy_url.txt` - Privacy policy URL
- `support_url.txt` - Support URL

## Screenshots

Screenshots should be placed in `fastlane/screenshots/en-US/` with these naming conventions:

- iPhone: `iPhone67-1.png`, `iPhone67-2.png`, etc.
- iPhone Pro: `iPhone65-1.png`, `iPhone65-2.png`, etc.
- iPad: `iPad-1.png`, `iPad-2.png`, etc.

## Troubleshooting

### Common Issues

1. **"Invalid Credentials"**
   - Verify Apple ID and app-specific password
   - Check 2FA is enabled on Apple ID
   - Ensure team ID is correct

2. **"App not found"**
   - Verify bundle identifier matches App Store Connect
   - Ensure app exists in App Store Connect
   - Check team ID has access to the app

3. **"Build processing failed"**
   - Wait for build processing to complete
   - Check for binary upload issues
   - Verify export method is "app-store"

4. **"Screenshots rejected"**
   - Ensure screenshot dimensions match device requirements
   - Check screenshot quality and content
   - Verify naming conventions

### Debug Mode

Run with verbose output for troubleshooting:
```bash
bundle exec fastlane ios deploy --verbose
```

## Security Best Practices

1. **Never commit credentials** - Use environment variables or .env files
2. **Restrict API key permissions** - Use minimum required permissions
3. **Rotate passwords regularly** - Update app-specific passwords periodically
4. **Use separate keys for CI** - Different keys for development vs automation

## Next Steps

1. Configure your authentication method (Apple ID or API key)
2. Update the metadata files with your app information
3. Test with `bundle exec fastlane ios metadata_only` first
4. Generate and organize screenshots
5. Run full deployment with `bundle exec fastlane ios deploy`

For more information, see:
- [Fastlane Deliver Documentation](https://docs.fastlane.tools/actions/deliver/)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)