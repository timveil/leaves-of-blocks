# Constants.rb
# Shared constants for Fastlane configuration files.
# Loaded from Deliverfile, Fastfile, and Snapfile via a Dir.pwd-resolved
# `require` (require_relative breaks under fastlane's eval-based loader on
# Ruby 3.x+ — "cannot infer basepath").

# App Configuration
APP_IDENTIFIER = ENV["LOCAL_FASTLANE_APP_IDENTIFIER"] || "timothy.veil.LeavesOfBlocks"
XCODE_PROJECT = "LeavesOfBlocks.xcodeproj"
MAIN_SCHEME = "LeavesOfBlocks"

# Public repository URL — used by the changelog updater to build compare
# links in CHANGELOG.md footers ([1.2.3]: <url>/compare/v1.2.2...v1.2.3).
REPO_URL = "https://github.com/timveil/leaves-of-blocks"

# Developer Information
# These are used in App Store Connect review submissions (see app_review_info below).
# Sourced from environment variables so personal contact details are not committed to the repo.
# Set them in fastlane/.env (see fastlane/.env.template).
DEVELOPER_NAME = ENV["LOCAL_FASTLANE_DEVELOPER_FIRST_NAME"]
DEVELOPER_LAST_NAME = ENV["LOCAL_FASTLANE_DEVELOPER_LAST_NAME"]
DEVELOPER_PHONE = ENV["LOCAL_FASTLANE_DEVELOPER_PHONE"]
DEVELOPER_EMAIL = ENV["LOCAL_FASTLANE_DEVELOPER_EMAIL"]

# Build Configuration
#
# The Xcode requirement is a MINIMUM, declared once in .xcode-version at the
# repository root and enforced by scripts/xcode-version.sh -- which the CI
# workflows read too, so the number is never re-encoded (see
# conventions/shared-rule-single-source.md).
#
# It used to be an exact pin here. That meant every Xcode auto-update broke
# every lane at before_all until someone edited this file: moving to 26.6
# against a hardcoded 26.5 took out `beta`, `deploy`, `screenshots` and
# `test_api_auth` at once, with releases blocked until the constant changed.
# A floor does not have that failure mode.
# Resolve the repository root by looking for a file known to live there.
#
# fastlane runs with Dir.pwd at either the repo root or fastlane/ depending on
# how it was invoked, so no fixed relative path is safe. Every caller that
# needs a repo-relative file goes through this rather than guessing -- guessing
# is how a working check reports a false failure (conventions/shared-rule-single-source.md).
def project_root(marker)
  ['..', '.'].map { |d| File.expand_path(d, Dir.pwd) }
             .find { |d| File.exist?(File.join(d, marker)) }
end

def ensure_minimum_xcode_version!
  require 'shellwords'

  root = project_root('.xcode-version')

  unless root
    FastlaneCore::UI.user_error!("Could not locate .xcode-version starting from #{Dir.pwd}")
  end

  script = File.join(root, 'scripts', 'xcode-version.sh')
  output = `#{script.shellescape} --check 2>&1`

  if $?.success?
    FastlaneCore::UI.success(output.strip)
  else
    # The script explains what to do; pass its message through rather than
    # replacing it with a vaguer one.
    FastlaneCore::UI.user_error!(output.strip)
  end
end
# Device names stay pinned deliberately.
#
# SCREENSHOT_DEVICES is a product decision, not an incidental one: App Store
# screenshots are submitted at specific display sizes, so the device is chosen
# rather than discovered. IOS_SIMULATOR is closer to incidental -- it only
# names a destination for the `test` and `build_for_testing` lanes -- but
# scripts/build.sh already does discovery for the everyday path, and having
# fastlane silently pick a different device than the one a failure was reported
# on is worse than being told the pinned one is missing.
IOS_SIMULATOR = "iPhone 17 Pro"

# The simulator runtime is derived, not pinned. It used to be a constant here
# whose comment read "Update when the runtime changes" -- a maintenance task
# whose only reminder was a release failing partway through, since screenshots
# run inside `deploy`.
#
# scripts/simulator-runtime.sh picks the newest installed runtime at or above
# the app's IPHONEOS_DEPLOYMENT_TARGET, read from the project so the floor has
# no second copy. It returns the POINT version ("26.4.1"), which is what
# xcodebuild's -destination matches against; see the DeviceManager patch at the
# bottom of this file for why the label form ("26.4") is not interchangeable.
#
# A method rather than a constant so only screenshot runs pay for it: this file
# is loaded by the Deliverfile and Snapfile too, and a lane that never touches a
# simulator should not fail because none is installed.
def simulator_runtime_version
  root = project_root(File.join('scripts', 'simulator-runtime.sh'))

  unless root
    FastlaneCore::UI.user_error!("Could not locate scripts/simulator-runtime.sh from #{Dir.pwd}")
  end

  require 'shellwords'
  script = File.join(root, 'scripts', 'simulator-runtime.sh')
  output = `#{script.shellescape} 2>&1`.strip

  # The script explains what to install and how; pass its message through
  # rather than replacing it with a vaguer one.
  FastlaneCore::UI.user_error!(output) unless $?.success? && !output.empty?

  FastlaneCore::UI.message("Simulator runtime: #{output}")
  output
end
EXPORT_METHOD = "app-store"
TEAM_ID = "85U9MWUBJL"

# Distribution signing helper used by every lane that calls `build_app` for
# App Store export. Calls `cert` + `sigh` via the App Store Connect API key
# (App Manager role required) to materialize an Apple Distribution cert and
# an App Store provisioning profile, then returns a gym `export_options`
# hash that points the export step at that profile by name.
#
# Why this exists: `xcodebuild -exportArchive` (the CLI used by gym) cannot
# auto-create distribution profiles — only Xcode IDE can. Without local
# cert + profile, automatic signing fails with "No profiles for '<bundle
# id>' were found". Manual signing with a known-good profile name works
# regardless of what's in the keychain at the start of the run.
#
# Not frozen: gym mutates this hash while writing the export options plist.
def app_store_signing_options(api_key:)
  get_certificates(api_key: api_key)
  get_provisioning_profile(
    api_key: api_key,
    app_identifier: APP_IDENTIFIER
  )
  {
    signingStyle: "manual",
    teamID: TEAM_ID,
    provisioningProfiles: {
      APP_IDENTIFIER => lane_context[Fastlane::Actions::SharedValues::SIGH_NAME]
    }
  }
end

# Screenshot Configuration
SCREENSHOT_DEVICES = [
  "iPhone 17 Pro Max"
]
# Kept in step with .locales by scripts/check-locales.sh, which fails CI if
# this list and the manifest disagree.
SCREENSHOT_LANGUAGES = [
  "en-US",
  "es-MX"
]

# Fastlane Paths
METADATA_PATH = "./fastlane/metadata"
SCREENSHOTS_PATH = "./fastlane/screenshots"

# Environment Variables
API_KEY_ID = ENV["LOCAL_APP_STORE_CONNECT_API_KEY_ID"]
ISSUER_ID = ENV["LOCAL_APP_STORE_CONNECT_ISSUER_ID"]
API_KEY_FILE_PATH = ENV["LOCAL_APP_STORE_CONNECT_API_KEY_PATH"]

# App Store Configuration
APP_DESCRIPTION = "Leaves of Blocks is a Whitman-inspired block puzzle game. Offline gameplay with optional Apple Game Center support for leaderboards and achievements (off by default). No ads, no third-party tracking, no data sold, no in-app purchases. All features are available immediately upon download. The game includes comprehensive statistics tracking and game history stored locally using Core Data."

# Submission Information Hash
SUBMISSION_INFO = {
  add_id_info_limits_tracking: true,
  add_id_info_serves_ads: false,
  add_id_info_tracks_action: false,
  add_id_info_tracks_install: false,
  add_id_info_uses_idfa: false,
  content_rights_has_rights: true,
  content_rights_contains_third_party_content: false,
  export_compliance_platform: 'ios',
  export_compliance_compliance_required: false,
  export_compliance_encryption_updated: false,
  export_compliance_app_type: nil,
  export_compliance_uses_encryption: false,
  export_compliance_is_exempt: false,
  export_compliance_contains_third_party_cryptography: false,
  export_compliance_contains_proprietary_cryptography: false,
  export_compliance_available_on_french_store: false
}

# App Review Information Hash
def app_review_info
  {
    first_name: DEVELOPER_NAME,
    last_name: DEVELOPER_LAST_NAME,
    phone_number: DEVELOPER_PHONE,
    email_address: DEVELOPER_EMAIL,
    demo_user: "",
    demo_password: "",
    notes: APP_DESCRIPTION
  }
end

# Helper method for API key configuration
# The in_house parameter may be required for match/sigh actions
def api_key_config(in_house: false)
  # Check if required environment variables are set. Use UI.user_error! so
  # the failure prints with fastlane's standard formatting and the lane's
  # `error do` hook fires (a plain `raise` skips both). Constants.rb is
  # loaded via `require` (outside fastlane's eval scope), so the bare `UI`
  # constant is not in lexical scope here — call FastlaneCore::UI directly.
  unless API_KEY_ID && ISSUER_ID
    FastlaneCore::UI.user_error!("Missing required environment variables: LOCAL_APP_STORE_CONNECT_API_KEY_ID and LOCAL_APP_STORE_CONNECT_ISSUER_ID must be set in fastlane/.env")
  end

  unless API_KEY_FILE_PATH
    FastlaneCore::UI.user_error!("Missing required environment variable: LOCAL_APP_STORE_CONNECT_API_KEY_PATH must be set in fastlane/.env")
  end

  unless File.exist?(API_KEY_FILE_PATH)
    FastlaneCore::UI.user_error!("API key file not found at: #{API_KEY_FILE_PATH}")
  end

  app_store_connect_api_key(
    key_id: API_KEY_ID,
    issuer_id: ISSUER_ID,
    key_filepath: API_KEY_FILE_PATH,
    duration: 1200,
    in_house: in_house
  )
end

# Helper method for App Store/TestFlight operations (standard App Store distribution)
def app_store_api_key
  api_key_config(in_house: false)
end

# Helper method for Enterprise/In-House distribution (if needed for match/sigh)
def enterprise_api_key
  api_key_config(in_house: true)
end

# macOS notification helper. Replaces fastlane's `notification` action, which
# bundles an x86_64-only `terminal-notifier` binary that errors with "Bad CPU
# type" on Apple Silicon without Rosetta installed.
def macos_notification(message:, title: "fastlane")
  escaped_message = message.to_s.gsub('\\', '\\\\').gsub('"', '\\"')
  escaped_title = title.to_s.gsub('\\', '\\\\').gsub('"', '\\"')
  system("osascript", "-e", %(display notification "#{escaped_message}" with title "#{escaped_title}"))
rescue StandardError
  nil
end

# Still required alongside simulator_runtime_version, and the two solve halves
# of the same mismatch: that method supplies the POINT version to snapshot,
# while this patch makes DeviceManager report point versions for the devices
# snapshot matches it against. Fix only one and nothing matches -- supply a
# point version to a DeviceManager reporting labels, or a label to xcodebuild,
# and the destination resolves to no simulator.
#
# fastlane's DeviceManager parses the `-- iOS 26.4 --` section header from
# `xcrun simctl list devices` text output and uses that label as the device's
# os_version. When the runtime's installed point version differs (e.g. the
# "iOS 26.4" runtime is actually "26.4.1"), xcodebuild's `-destination` rejects
# `OS:26.4` because the device reports `OS:26.4.1`. Backfill the point version
# from `xcrun simctl list -j runtimes` so destinations match.
require 'json'
require 'open3'

module FastlaneCoreDevicePointVersionFix
  def simulators(*args, **kwargs)
    devices = super
    mapping = _runtime_name_to_version
    devices.each do |d|
      full = mapping["#{d.os_type} #{d.os_version}"]
      if full && full != d.os_version
        d.os_version = full
        d.ios_version = full
      end
    end
    devices
  end

  def _runtime_name_to_version
    @_runtime_name_to_version ||= begin
      out, status = Open3.capture2('xcrun', 'simctl', 'list', '-j', 'runtimes')
      if status.success?
        JSON.parse(out).fetch('runtimes', []).each_with_object({}) do |r, h|
          h[r['name']] = r['version'] if r['isAvailable']
        end
      else
        {}
      end
    rescue StandardError
      {}
    end
  end
end

FastlaneCore::DeviceManager.singleton_class.prepend(FastlaneCoreDevicePointVersionFix)

# fastlane snapshot's HTML report (`screenshots.html`) maps screenshot filenames
# to device sections via a hardcoded list that stops at iPhone 15. Screenshots
# from newer devices (iPhone 16/17/Air etc.) get filtered out and the report
# renders empty. Extend the mapping with the modern iPhone lineup.
begin
  require 'snapshot/reports_generator'
  module SnapshotReportsModernDevices
    EXTRA_DEVICES = {
      'iPhone Air' => 'iPhone Air',
      'iPhone 17 Pro Max' => 'iPhone 17 Pro Max',
      'iPhone 17 Pro' => 'iPhone 17 Pro',
      'iPhone 17e' => 'iPhone 17e',
      'iPhone 17' => 'iPhone 17',
      'iPhone 16 Pro Max' => 'iPhone 16 Pro Max',
      'iPhone 16 Pro' => 'iPhone 16 Pro',
      'iPhone 16 Plus' => 'iPhone 16 Plus',
      'iPhone 16e' => 'iPhone 16e',
      'iPhone 16' => 'iPhone 16'
    }.freeze

    def xcode_9_and_above_device_name_mappings
      EXTRA_DEVICES.merge(super)
    end
  end
  Snapshot::ReportsGenerator.prepend(SnapshotReportsModernDevices)
rescue LoadError
  # snapshot not loaded in this fastlane context — skip silently
end