# Constants.rb
# Shared constants for Fastlane configuration files.
# Loaded from Deliverfile, Fastfile, and Snapfile via a Dir.pwd-resolved
# `require` (require_relative breaks under fastlane's eval-based loader on
# Ruby 3.x+ — "cannot infer basepath").

# App Configuration
APP_IDENTIFIER = ENV["LOCAL_FASTLANE_APP_IDENTIFIER"] || "timothy.veil.LeavesOfBlocks"
XCODE_PROJECT = "LeavesOfBlocks.xcodeproj"
MAIN_SCHEME = "LeavesOfBlocks"

# Developer Information
# These are used in App Store Connect review submissions (see app_review_info below).
# Sourced from environment variables so personal contact details are not committed to the repo.
# Set them in fastlane/.env (see fastlane/.env.example).
DEVELOPER_NAME = ENV["LOCAL_FASTLANE_DEVELOPER_FIRST_NAME"]
DEVELOPER_LAST_NAME = ENV["LOCAL_FASTLANE_DEVELOPER_LAST_NAME"]
DEVELOPER_PHONE = ENV["LOCAL_FASTLANE_DEVELOPER_PHONE"]
DEVELOPER_EMAIL = ENV["LOCAL_FASTLANE_DEVELOPER_EMAIL"]

# Build Configuration
XCODE_VERSION = "26.4.1"
# Pin the iOS Simulator runtime version. fastlane's snapshot auto-detection
# uses the runtime label ("iOS 26.4"), but xcodebuild's `-destination` needs
# the installed point version ("26.4.1"). Update when the runtime changes.
IOS_VERSION = "26.4.1"
IOS_SIMULATOR = "iPhone 17 Pro"
EXPORT_METHOD = "app-store"

# Screenshot Configuration
SCREENSHOT_DEVICES = [
  "iPhone 17 Pro"
]
SCREENSHOT_LANGUAGES = [
  "en-US"
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
  # Check if required environment variables are set
  unless API_KEY_ID && ISSUER_ID
    raise "Missing required environment variables: APP_STORE_CONNECT_API_KEY_ID and APP_STORE_CONNECT_ISSUER_ID must be set"
  end
  
  unless API_KEY_FILE_PATH
    raise "Missing required environment variable: APP_STORE_CONNECT_API_KEY_PATH must be set"
  end
  
  unless File.exist?(API_KEY_FILE_PATH)
    raise "API key file not found at: #{API_KEY_FILE_PATH}"
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