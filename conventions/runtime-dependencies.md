# No third-party runtime dependencies

**The app links system frameworks only:** SwiftUI, SpriteKit, GameKit, Core
Data, Foundation. No SPM packages, no CocoaPods, no vendored SDKs.

`LeavesOfBlocks.xcodeproj` contains no package references, and that is a
property to preserve, not an accident to correct.

## Why

It is what makes the app's privacy claim checkable rather than asserted. The
posture — no ads, no third-party tracking, no data sold, no IDFA, no ATT prompt
— is only as strong as the dependency list behind it. One analytics SDK, however
well-behaved, turns a verifiable statement into a promise about someone else's
code, and invalidates
[`PrivacyInfo.xcprivacy`](../LeavesOfBlocks/Resources/PrivacyInfo.xcprivacy)
along with the App Store metadata.

It also means the only network traffic the app can produce is GameKit's, which
is off by default and opt-in.

The second-order benefit is that the build has no supply chain: nothing to
audit, nothing to pin, nothing that breaks on an Xcode upgrade because an
upstream maintainer moved on.

## Scope

This applies to the **app target**. Development tooling is a different question
— fastlane and its gems are dependencies of the release process, managed through
`Gemfile.lock` and dependabot, and never ship inside the binary.

## If you are reaching for a dependency

Say what it would do, then check whether a system framework already does it.
For a game of this size the answer has so far always been yes. If it genuinely
is not, that is a conversation to have in an issue before writing the code — the
privacy copy in `Localizable.xcstrings` (`technical_description`),
`fastlane/Constants.rb` (`APP_DESCRIPTION`), and `fastlane/AIHelper.rb`
(`APP_CONTEXT`) would all need revising alongside it.

## Enforcement

Review, plus CodeQL. A package reference appearing in `project.pbxproj` should
be treated as a blocking review comment, not a detail.
