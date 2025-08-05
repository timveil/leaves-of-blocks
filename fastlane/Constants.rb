# Constants.rb
# Shared constants for Fastlane configuration files
# Import this file in Deliverfile, Fastfile, and Snapfile with: require_relative 'Constants'

# App Configuration
APP_IDENTIFIER = ENV["FASTLANE_APP_IDENTIFIER"]
APP_CLIP_IDENTIFIER = "timothy.veil.LeavesOfBlocks.Clip"
XCODE_PROJECT = "LeavesOfBlocks.xcodeproj"
MAIN_SCHEME = "LeavesOfBlocks"
APP_CLIP_SCHEME = "LeavesOfBlocksAppClip"

# Developer Information
DEVELOPER_NAME = "Tim"
DEVELOPER_LAST_NAME = "Veil"
DEVELOPER_PHONE = "+1 678 296 7960"
DEVELOPER_EMAIL = "timveil@mac.com"

# Build Configuration
XCODE_VERSION = "16.4"
IOS_SIMULATOR = "iPhone 16"
EXPORT_METHOD = "app-store"

# Screenshot Configuration
SCREENSHOT_DEVICES = [
  "iPhone 15 Pro Max"   # 1290x2796 - 6.7" displays (required for App Store Connect)
]
SCREENSHOT_LANGUAGES = [
  "en-US"
]

# Fastlane Paths
METADATA_PATH = "./fastlane/metadata"
SCREENSHOTS_PATH = "./fastlane/screenshots"

# Environment Variables
API_KEY_ID = ENV["APP_STORE_CONNECT_API_KEY_ID"]
ISSUER_ID = ENV["APP_STORE_CONNECT_ISSUER_ID"]
API_KEY_FILE_PATH = ENV["APP_STORE_CONNECT_API_KEY_PATH"]

# App Store Configuration
APP_DESCRIPTION = "Leaves of Blocks is a Whitman-inspired block puzzle game. The app is completely offline with no network requests, no ads, no tracking, and no in-app purchases. All features are available immediately upon download. The game includes comprehensive statistics tracking and game history stored locally using Core Data."

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