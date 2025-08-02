fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios test

```sh
[bundle exec] fastlane ios test
```

Run tests

### ios build_for_testing

```sh
[bundle exec] fastlane ios build_for_testing
```

Build for testing

### ios build

```sh
[bundle exec] fastlane ios build
```

Create a new build for App Store

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Upload to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Upload to App Store

### ios metadata_only

```sh
[bundle exec] fastlane ios metadata_only
```

Upload metadata and screenshots only (no binary)

### ios screenshots_only

```sh
[bundle exec] fastlane ios screenshots_only
```

Upload screenshots only

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Complete App Store deployment with metadata and binary

### ios submit

```sh
[bundle exec] fastlane ios submit
```

Submit for App Store review (use after deploy)

### ios deploy_and_submit

```sh
[bundle exec] fastlane ios deploy_and_submit
```

Full deployment pipeline: build, upload, and submit for review

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Generate new localized screenshots

### ios manual_screenshots

```sh
[bundle exec] fastlane ios manual_screenshots
```

Generate manual screenshots (simulator only)

### ios build_app_clip

```sh
[bundle exec] fastlane ios build_app_clip
```

App Clip build

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
