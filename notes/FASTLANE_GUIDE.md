# Fastlane Directory Structure Guide

## Overview

Fastlane is an automation tool for iOS and Android deployment. The `fastlane/` directory contains all the configuration files, scripts, and assets needed to automate building, testing, screenshot generation, and App Store deployment for the Leaves of Blocks game.

## Directory Structure

```
fastlane/
├── Configuration Files
│   ├── Fastfile              # Main automation scripts and lanes
│   ├── Appfile               # App and team identifiers
│   ├── Deliverfile           # App Store upload configuration
│   └── Snapfile              # Screenshot generation configuration
├── Authentication
│   ├── AuthKey_B8G72J8L8W.json  # App Store Connect API key (JSON format)
│   └── AuthKey_B8G72J8L8W.p8    # App Store Connect API key (P8 format)
├── Documentation
│   ├── README.md             # Fastlane setup instructions
│   ├── APP_STORE_SETUP.md    # App Store Connect configuration guide
│   └── SCREENSHOT_SETUP.md   # Screenshot automation guide
├── App Store Metadata
│   └── metadata/
│       ├── en-US/            # English (US) app store listing
│       │   ├── description.txt
│       │   ├── keywords.txt
│       │   ├── name.txt
│       │   ├── subtitle.txt
│       │   ├── promotional_text.txt
│       │   ├── release_notes.txt
│       │   ├── marketing_url.txt
│       │   ├── privacy_url.txt
│       │   └── support_url.txt
│       ├── copyright.txt
│       ├── primary_category.txt
│       └── secondary_category.txt
├── Screenshots
│   └── screenshots/
│       ├── en-US/            # English screenshots
│       │   ├── iPhone 15 Pro Max-01_HomeScreen.png
│       │   ├── iPhone 15 Pro Max-02_Gameplay.png
│       │   ├── iPhone 15 Pro Max-03_GameHistory.png
│       │   └── iPhone 15 Pro Max-04_GameDetail.png
│       └── screenshots.html  # HTML report of generated screenshots
├── Generated Files
│   ├── SnapshotHelper.swift  # UI testing helper for screenshots
│   └── report.xml            # Test execution report
└── Legacy
    └── fastlane/             # Legacy directory (can be removed)
```

## Key Files Explained

### Configuration Files

#### Fastfile
The heart of your Fastlane setup. Contains "lanes" (automated workflows) for:

**Development Lanes:**
- `test` - Run unit and UI tests
- `build_for_testing` - Build app for simulator testing
- `screenshots` - Generate App Store screenshots automatically
- `manual_screenshots` - Instructions for manual screenshot capture
- `clean` - Clean build artifacts and temporary files

**App Store Deployment Lanes:**
- `deploy` - Complete App Store deployment (binary + metadata + screenshots)
- `submit` - Submit already uploaded build for App Store review
- `deploy_and_submit` - Full pipeline: build, upload, and submit for review
- `metadata_only` - Upload only metadata and screenshots (no binary)
- `screenshots_only` - Upload only screenshots
- `release` - Legacy upload to App Store (basic)
- `beta` - Upload to TestFlight for beta testing

**Utility Lanes:**
- `build` - Create App Store build
- `build_app_clip` - Build the App Clip target
- `update_changelog` - Update CHANGELOG.md for new releases

**Special Features:**
- Automatic changelog integration for TestFlight uploads
- Build number auto-increment
- App Store Connect API key management
- Comprehensive error handling and success notifications

#### Appfile
Simple configuration file containing:
- App bundle identifier: `timothy.veil.LeavesOfBlocks`
- Developer team ID: `85U9MWUBJL`
- Apple ID (commented out, can be set via environment variable)

#### Deliverfile
Comprehensive App Store upload configuration:
- App metadata paths
- Screenshots configuration
- Submission settings (review, release options)
- App review information (contact details, notes)
- Export compliance settings
- Privacy and content rights declarations

#### Snapfile
Screenshot automation configuration:
- Target devices: iPhone 15 Pro Max (6.7" display)
- Languages: English (US)
- UI testing scheme: LeavesOfBlocks
- Launch arguments for screenshot mode
- Status bar customization (9:41 AM, full battery)

### Authentication Files

#### AuthKey Files
Two formats of the same App Store Connect API key:
- `.json` - Used by newer Fastlane versions
- `.p8` - Traditional format
- Key ID: `B8G72J8L8W`
- Used for authenticating with App Store Connect API

**Security Note:** These files contain sensitive authentication credentials and should never be committed to public repositories.

### App Store Metadata

The `metadata/` directory contains all text content for your App Store listing:

#### English (en-US) Metadata
- **description.txt** - Full app description (Whitman-inspired, puzzle game focus)
- **name.txt** - App name as it appears in the App Store
- **subtitle.txt** - Short description under the app name
- **keywords.txt** - App Store search keywords
- **promotional_text.txt** - Promotional text that can be updated without review
- **release_notes.txt** - What's new in this version
- **marketing_url.txt** - App website or marketing page
- **privacy_url.txt** - Privacy policy URL
- **support_url.txt** - Customer support URL

#### Global Metadata
- **copyright.txt** - Copyright notice
- **primary_category.txt** - Main App Store category (Games)
- **secondary_category.txt** - Secondary category (Puzzle)

### Screenshots Directory

Contains App Store screenshots organized by:
- Language (en-US)
- Device size (iPhone 15 Pro Max - 6.7" displays)
- Screen sequence (01-04, representing different app screens)

Screenshots are automatically uploaded to App Store Connect and must match Apple's size requirements.

## Common Workflows

### Development Testing
```bash
# Run all tests
bundle exec fastlane ios test

# Generate screenshots
bundle exec fastlane ios screenshots

# Clean build artifacts
bundle exec fastlane ios clean
```

### App Store Deployment

#### Recommended Workflow
```bash
# 1. Complete deployment (recommended)
bundle exec fastlane ios deploy

# 2. Submit for review when ready
bundle exec fastlane ios submit
```

#### Alternative Workflows
```bash
# All-in-one deployment
bundle exec fastlane ios deploy_and_submit

# Upload only metadata/screenshots
bundle exec fastlane ios metadata_only

# TestFlight beta
bundle exec fastlane ios beta
```

### Changelog Management
```bash
# Update changelog for new version
bundle exec fastlane ios update_changelog version:1.0.4
```

## File Management Tips

### What to Commit
- All configuration files (Fastfile, Appfile, Deliverfile, Snapfile)
- Documentation files
- Metadata text files
- Generated SnapshotHelper.swift

### What NOT to Commit
- AuthKey files (`.json`, `.p8`) - Contains sensitive credentials
- Screenshots (large binary files, generated content)
- Generated reports (`report.xml`)
- Build artifacts and temporary files

### What to Gitignore
```gitignore
# Fastlane
fastlane/AuthKey_*.json
fastlane/AuthKey_*.p8
fastlane/screenshots/
fastlane/report.xml
fastlane/test_output/
```

## Troubleshooting

### Common Issues
1. **Authentication Errors** - Ensure AuthKey files are present and valid
2. **Screenshot Failures** - Check Snapfile device names match available simulators
3. **Build Failures** - Verify Xcode version requirements in Fastfile
4. **Metadata Errors** - Check text file encoding and content length limits

### Environment Variables
Fastlane can use environment variables for sensitive data:
- `FASTLANE_USER` - Apple ID email
- `APP_STORE_CONNECT_API_KEY_ID` - API key ID
- `APP_STORE_CONNECT_ISSUER_ID` - Issuer ID
- `APP_STORE_CONNECT_API_KEY_PATH` - Path to API key file

## Integration with Project

### Menu System Integration
The project's `menu.sh` script provides easy access to Fastlane commands:
- Options 6-10: Fastlane operations
- Automatic command execution with proper directory context

### CLAUDE.md Integration
The project's documentation references Fastlane commands for:
- Changelog management workflow
- Beta deployment automation
- App Store deployment pipeline

### Version Management
Fastlane integrates with the project's version management:
- Automatic build number increment
- Changelog content extraction for TestFlight
- Version synchronization across main app and App Clip

This comprehensive Fastlane setup enables fully automated iOS app deployment while maintaining flexibility for different release workflows and requirements.