# Security Policy

## Supported Versions

Only the latest release of Leaves of Blocks receives security updates. The app is a single-player iOS game with no analytics, no third-party SDKs, and no remote services beyond Apple's own Game Center (which is opt-in and off by default). The attack surface is intentionally small.

| Version | Supported |
|---------|-----------|
| Latest release on the App Store | Yes |
| Older releases                  | No  |

## Reporting a Vulnerability

If you believe you have found a security issue, **please do not file a public GitHub issue**. Instead, report it privately so it can be triaged before any details become public.

There are two preferred channels:

1. **GitHub private vulnerability reporting** (preferred). Open the repository's
   [Security tab](https://github.com/timveil/leaves-of-blocks/security/advisories/new)
   and submit a new advisory. This keeps the report private until a fix is ready.
2. **Email**. Send a description of the issue to **tjveil@gmail.com**. Please include
   the word `security` in the subject line.

When reporting, please include:

- A description of the issue and its potential impact.
- Steps to reproduce, ideally with a minimal example.
- The iOS version, device, and app version where you observed the issue.
- Any relevant logs, screenshots, or sample code.

You should receive an acknowledgement within **72 hours**. After triage, expect a follow-up within **7 days** with either a planned fix timeline or an explanation of why the report does not require action.

## Scope

In scope:

- The Leaves of Blocks iOS app shipped via the App Store and the source in this repository.
- Build and release tooling under `fastlane/`, `scripts/`, and `.github/workflows/`.

Out of scope:

- Bugs that do not have a security impact (please file a regular GitHub issue).
- Vulnerabilities in third-party services or in the iOS platform itself; please report those to the respective vendors.
- Issues that require a jailbroken device or physical access to an unlocked device.

## Disclosure

Once a fix is available and shipped, the original reporter will be credited in the release notes unless they request otherwise.
