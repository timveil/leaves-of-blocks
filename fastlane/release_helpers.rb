# release_helpers.rb
# Helpers for the App Store release pipeline.
#
# Loaded from the Fastfile via the same Dir.pwd-resolved `require` pattern as
# Constants.rb / AIHelper.rb (require_relative breaks under fastlane's
# eval-based loader on Ruby 3.x+, and `load` re-runs the file on every
# fastlane pass which would emit "already initialized constant" warnings).
#
# Methods defined here run inside fastlane's lane context, so they can call
# fastlane actions (sh, UI, build_app, deliver, etc.) and other lanes
# directly — same as if they were defined inline in the Fastfile.
#
# ─────────────────────────────────────────────────────────────────────────────
# Logging conventions
# ─────────────────────────────────────────────────────────────────────────────
# These helpers run during release flows where the lane log is the only
# post-mortem when something goes wrong. Use the right severity so a quick
# scan distinguishes "still working" from "milestone passed" from "things
# going sideways":
#
#   UI.success     — a state-changing milestone the human cares about: a
#                    commit was made, a tag was pushed, the binary was
#                    delivered. Roughly one per major phase. Climactic, not
#                    "this method finished without throwing."
#
#   UI.message     — neutral progress and informational lines.
#
#   UI.important   — notable runtime state that's not an error but is worth
#                    flagging (e.g. "no commits derived from changelog",
#                    "carrying over manual [Unreleased] notes", AI fallback
#                    paths). Currently underused.
#
#   UI.error       — actual errors. The body of the post-failure recovery
#                    block in the `error do` hook MAY also use UI.error for
#                    visual cohesion with the error itself.
#
#   UI.user_error! — fatal: aborts the lane and triggers the `error do` hook.
#                    Use any time we want fastlane to stop with a tidy message.
#
# Format conventions:
#   "key: value"       static facts            (Current version: 2.0.3)
#   "from → to"        transitions             (Version bumped: 2.0.3 → 2.0.4)
#   "▸ Phase name"     step markers — only in _release_core, not helpers
#                      (helpers may be reused from other contexts later)
#
# Emoji policy:
#   - Helpers do NOT emit emoji. They run identically across both deploy
#     lanes; emoji decoration is noise inside a helper.
#   - The lane-level summary block at the end of _release_core uses emoji as
#     icons (📱 binary / 🏷️ tag / ⏳ waiting) — these encode meaning, not
#     decoration, and only run once per release.
#   - GameCenterClient's category emoji (🏁/🏆 + ＋/↺) are intentional and
#     out of scope for this convention — they encode action vs category.
# ─────────────────────────────────────────────────────────────────────────────

# Resolve a bump_type ("patch" / "minor" / "major" / "X.Y.Z") into a concrete
# version string. Rejects anything else with UI.user_error! so a typo or
# misnamed lane argument can't silently downgrade the marketing version
# (this is the bug class that hardcoded "2.0.0" got into the beta lane and
# went unnoticed across multiple releases).
SEMVER_REGEX = /\A\d+\.\d+\.\d+\z/.freeze

# Which version a release should ship.
#
# MARKETING_VERSION states the version under development, so with no bump_type
# a release ships exactly that. A bump_type is how you change train -- minor,
# major, or an explicit number -- and is applied to the current value.
#
# Pure so the rule can be tested without a project file; _release_core supplies
# the current version by reading one.
def _resolve_target_version(current:, bump_type:)
  return current if bump_type.nil? || bump_type.to_s.strip.empty?

  _resolve_bump(current: current, bump_type: bump_type)
end

def _resolve_bump(current:, bump_type:)
  parts = current.split('.').map(&:to_i)
  parts << 0 while parts.length < 3

  case bump_type
  when "patch"
    "#{parts[0]}.#{parts[1]}.#{parts[2] + 1}"
  when "minor"
    "#{parts[0]}.#{parts[1] + 1}.0"
  when "major"
    "#{parts[0] + 1}.0.0"
  when SEMVER_REGEX
    bump_type
  else
    FastlaneCore::UI.user_error!(
      "Invalid version bump '#{bump_type}'. Expected one of: " \
      "'patch', 'minor', 'major', or a semver string like '1.2.3'."
    )
  end
end

# Resolve the next build number from App Store Connect.
#
# App Store Connect is the only authority on which build numbers are already
# taken. The checked-in CURRENT_PROJECT_VERSION drifts out of step with it the
# moment a build is uploaded from another machine, a failed release run is
# undone with `git reset --hard`, or a bump lands on a branch that never
# merges. When it drifts low, the upload is rejected for a duplicate build
# number -- after the archive has already been built, which is the most
# expensive place in the pipeline to fail.
#
# Returns an Integer. Deliberately does NOT write to project.pbxproj: the value
# is handed to xcodebuild at archive time by app_store_build_app below, so the
# lanes leave a clean working tree and CURRENT_PROJECT_VERSION in the repo is
# no longer meaningful. ASC alone decides.
def next_build_number(api_key:)
  latest = latest_testflight_build_number(
    api_key: api_key,
    app_identifier: APP_IDENTIFIER,
    # Without this, the action hard-errors when the app has no builds at all
    # rather than falling back -- which would make a first upload impossible.
    initial_build_number: 0
  ).to_s.strip

  # This project uses a monotonically increasing integer scheme. A dotted or
  # otherwise non-integer value would be silently mangled by to_i ("1.2" -> 1),
  # producing a number that is very likely already taken.
  unless latest.match?(/\A\d+\z/)
    FastlaneCore::UI.user_error!(
      "App Store Connect returned a non-integer build number (#{latest.inspect}). " \
      "This project uses a monotonically increasing integer scheme -- investigate " \
      "before uploading."
    )
  end

  next_number = latest.to_i + 1
  FastlaneCore::UI.message("Build number: #{latest} on App Store Connect -> #{next_number}")
  next_number
end

# Archive for App Store distribution with the build number resolved from App
# Store Connect. Shared by every lane that produces an uploadable binary
# (`build`, `beta`, and `_release_core`), which previously repeated this call
# verbatim three times.
#
# The build number is passed as an xcodebuild setting override rather than
# written to disk. GENERATE_INFOPLIST_FILE is YES for this target, so
# CFBundleVersion in the archive is generated from CURRENT_PROJECT_VERSION --
# overriding it on the command line reaches the built product without touching
# the project file.
def app_store_build_app(api_key:, build_number: nil)
  build_number ||= next_build_number(api_key: api_key)

  build_app(
    project: XCODE_PROJECT,
    scheme: MAIN_SCHEME,
    export_method: EXPORT_METHOD,
    xcargs: "CURRENT_PROJECT_VERSION=#{build_number}",
    export_options: app_store_signing_options(api_key: api_key)
  )
end

# Bump MARKETING_VERSION directly via the xcodeproj gem.
# Works around `increment_version_number` failing under
# GENERATE_INFOPLIST_FILE=YES (it tries to update an Info.plist that doesn't
# exist as a file, aborts before persisting the project setting, and
# silently leaves the old version on the build).
# Locate a target's Release build configuration, failing with a readable
# message rather than a NoMethodError several lines later.
def release_build_configuration(target)
  config = target.build_configurations.find { |c| c.name == 'Release' }
  unless config
    available = target.build_configurations.map(&:name).join(', ')
    FastlaneCore::UI.user_error!(
      "Target '#{target.name}' has no 'Release' build configuration " \
      "(found: #{available.empty? ? 'none' : available}). The release flow reads " \
      "MARKETING_VERSION from Release and cannot continue without it."
    )
  end
  config
end

def bump_marketing_version(xcodeproj:, target_name:, version:)
  require 'xcodeproj'

  # Fastlane runs from fastlane/, so go up one level to reach the project.
  project_path = File.join(Dir.pwd, '..', xcodeproj)
  project = Xcodeproj::Project.open(project_path)

  target = project.targets.find { |t| t.name == target_name }
  FastlaneCore::UI.user_error!("Target '#{target_name}' not found") unless target

  current_version = release_build_configuration(target).build_settings['MARKETING_VERSION'] || '1.0.0'

  FastlaneCore::UI.message("Current version: #{current_version}")

  target.build_configurations.each do |config|
    config.build_settings['MARKETING_VERSION'] = version
  end
  project.save

  # Read the version back from a freshly opened project rather than trusting
  # the in-memory object. Everything downstream -- the archive, the App Store
  # submission, the git tag and the GitHub Release -- is named for `version`,
  # so a silent write failure here would ship a binary whose
  # CFBundleShortVersionString disagrees with its own tag.
  written = read_marketing_version(xcodeproj: xcodeproj, target_name: target_name)
  unless written == version
    FastlaneCore::UI.user_error!(
      "Version bump did not take: expected MARKETING_VERSION #{version}, " \
      "project now reports #{written.inspect}. Refusing to continue -- the tag " \
      "and the binary would not match."
    )
  end

  FastlaneCore::UI.message("Version bumped: #{current_version} → #{version}")
  version
end

# Read MARKETING_VERSION from the target's Release configuration.
def read_marketing_version(xcodeproj:, target_name:)
  require 'xcodeproj'

  project = Xcodeproj::Project.open(File.join(Dir.pwd, '..', xcodeproj))
  target = project.targets.find { |t| t.name == target_name }
  FastlaneCore::UI.user_error!("Target '#{target_name}' not found") unless target

  release_build_configuration(target).build_settings['MARKETING_VERSION']
end

# Calculate the new MARKETING_VERSION without applying it. Used pre-flight
# so we know the target version before mutating any disk state.
def calculate_new_version(xcodeproj:, target_name:, bump_type:)
  require 'xcodeproj'

  project_path = File.join(Dir.pwd, '..', xcodeproj)
  project = Xcodeproj::Project.open(project_path)

  target = project.targets.find { |t| t.name == target_name }
  FastlaneCore::UI.user_error!("Target '#{target_name}' not found") unless target

  current_version = release_build_configuration(target).build_settings['MARKETING_VERSION'] || '1.0.0'

  _resolve_bump(current: current_version, bump_type: bump_type)
end

# Extract bullet items from a single subsection of a CHANGELOG section.
def extract_items(content, header)
  pattern = /### #{header}\n((?:- .*\n?)*)/
  match = content.match(pattern)
  return [] unless match

  match[1].scan(/^- (.+)$/).flatten.map(&:strip).reject(&:empty?)
end

# Format a changelog subsection from a list of bullet items.
def format_changelog_section(header, items)
  return "" if items.empty?
  section = "\n### #{header}\n"
  items.each { |item| section += "- #{item}\n" }
  section
end

# Parse the body of the [Unreleased] section into a hash of
# { 'Added' => [items], 'Changed' => [items], 'Security' => [items], ... },
# preserving any non-standard subsections the maintainer added by hand.
# Returns an empty hash if [Unreleased] is missing or every subsection is
# empty. This is what powers the "manual notes get carried into the new
# release instead of silently dropped" behavior of update_changelog_from_commits.
def _parse_unreleased_subsections(changelog_content)
  # Match [Unreleased] body up to the next "## [" header, the link footer,
  # or EOF. The block is everything between the [Unreleased] header line
  # and the next top-level section.
  pattern = /## \[Unreleased\][^\n]*\n(.*?)(?=\n## \[|\n\[Unreleased\]:|\z)/m
  match = changelog_content.match(pattern)
  return {} unless match

  body = match[1]
  sections = {}

  # Each subsection is "### Header" followed by zero or more bullet lines,
  # ending at the next "### " or end-of-block.
  #
  # Anchored to line starts, and the header match stops at its own newline. An
  # earlier version used `### (\w+)\s*\n` with a `(?=\n### )` terminator: the
  # `\s*` swallowed the blank line after an EMPTY subsection, leaving the body
  # starting at the following "### " with no newline in front of it for the
  # lookahead to find. The next section's items were then attributed to the
  # empty one, and that section disappeared -- so a template [Unreleased] block
  # with an empty "### Added" above a populated "### Changed" reported the
  # changed items as added.
  body.scan(/^### (\w+)[^\n]*\n(.*?)(?=^### |\z)/m) do |header, items_block|
    bullets = items_block.scan(/^- (.+)$/).flatten.map(&:strip).reject(&:empty?)
    sections[header] = bullets unless bullets.empty?
  end

  sections
end

# Extract the body of one version's CHANGELOG section.
#
# A section runs from its "## [x.y.z]" heading to whichever comes first: the
# next "## [" heading, the "[Unreleased]:" link footer, or end of file. The
# footer matters -- without it the final section in the file swallows the whole
# link block, which then shows up verbatim in release notes.
#
# Returns the trimmed body, or nil when the section is absent or empty. Shared
# by generate_release_notes and publish_github_release so there is one
# definition of what a section is (conventions/shared-rule-single-source.md).
def extract_changelog_section(content, version)
  pattern = /## \[#{Regexp.escape(version)}\].*?\n(.*?)(?=\n## \[|\n\[Unreleased\]:|\z)/m
  match = content.match(pattern)
  return nil if match.nil? || match[1].strip.empty?

  match[1].strip
end

# Generate App Store release notes from CHANGELOG.md, preferring AI prose
# when ANTHROPIC_API_KEY is configured and falling back to a template.
def generate_release_notes(version:)
  changelog_path = File.join(Dir.pwd, '..', 'CHANGELOG.md')
  release_notes_path = File.join(Dir.pwd, 'metadata', 'en-US', 'release_notes.txt')

  unless File.exist?(changelog_path)
    FastlaneCore::UI.important("CHANGELOG.md not found, skipping release notes generation")
    return nil
  end

  content = File.read(changelog_path)

  # Try to find the section for this version, or fall back to [Unreleased].
  section_content = extract_changelog_section(content, version)
  section_content ||= extract_changelog_section(content, 'Unreleased')

  if section_content.nil?
    FastlaneCore::UI.important("No changelog entries found for version #{version}")
    return nil
  end

  # === AI PROSE GENERATION ATTEMPT ===
  prose = nil
  if AIHelper.available?
    FastlaneCore::UI.message("Attempting AI-generated release notes...")
    prose = AIHelper.generate_prose(changelog_section: section_content, version: version)

    if prose
      FastlaneCore::UI.message("AI prose generation succeeded")
    else
      FastlaneCore::UI.important("AI prose generation returned no results, using template fallback")
    end
  else
    FastlaneCore::UI.message("ANTHROPIC_API_KEY not set, using template-based release notes")
  end

  # === FALLBACK: Template-based generation ===
  unless prose
    added = extract_items(section_content, 'Added')
    changed = extract_items(section_content, 'Changed')
    fixed = extract_items(section_content, 'Fixed')
    improved = extract_items(section_content, 'Improved')

    sentences = []

    if added.any?
      sentences << "This update brings #{added.first.downcase}."
      if added.length > 1
        added[1..-1].each { |item| sentences << "We've also added #{item.downcase}." }
      end
    end

    all_improvements = changed + improved
    if all_improvements.any?
      all_improvements.each { |item| sentences << "We've improved #{item.downcase}." }
    end

    if fixed.any?
      sentences << "We've fixed #{fixed.first.downcase}."
      if fixed.length > 1
        fixed[1..-1].each { |item| sentences << "Also fixed: #{item.downcase}." }
      end
    end

    if sentences.empty?
      sentences << "This update includes various improvements and bug fixes."
    end

    sentences << ""
    sentences << "Thank you for playing Leaves of Blocks!"

    prose = sentences.join(" ").gsub("  ", " ").strip
    prose = prose.gsub("..", ".").gsub(". .", ".")
  end

  if prose.length > 4000
    prose = prose[0..3950] + "...\n\nThank you for playing Leaves of Blocks!"
  end

  File.write(release_notes_path, prose)
  FastlaneCore::UI.message("Release notes generated: #{version}")
  FastlaneCore::UI.message("Preview:\n#{prose}")

  prose
end

# Update CHANGELOG.md with a new section for new_version, derived from git
# commits since the last tag. Uses AI categorization when available, falls
# back to conventional-commit regex parsing.
#
# Returns the new section's content on success, or `false` when no entries
# were derived (in which case the caller should skip release-notes
# generation and let the user enter them manually in App Store Connect).
def update_changelog_from_commits(new_version:)
  changelog_path = File.join(Dir.pwd, '..', 'CHANGELOG.md')

  unless File.exist?(changelog_path)
    FastlaneCore::UI.user_error!("CHANGELOG.md not found at #{changelog_path}")
  end
  content = File.read(changelog_path)

  # Manual notes the maintainer added under [Unreleased] are extracted up
  # front. They get carried into the new release section so they aren't
  # silently dropped when [Unreleased] is reset. Custom subsections like
  # Security or Improved are preserved verbatim.
  manual_sections = _parse_unreleased_subsections(content)
  if manual_sections.any?
    summary = manual_sections.transform_values(&:length)
    FastlaneCore::UI.important("Carrying over manual [Unreleased] entries: #{summary.inspect}")
  end

  last_tag = `git describe --tags --abbrev=0 2>/dev/null`.strip

  if last_tag.empty?
    FastlaneCore::UI.message("No previous tags found, using all commits")
    range = ""
  else
    FastlaneCore::UI.message("Finding commits since #{last_tag}")
    range = "#{last_tag}..HEAD"
  end

  commits = `git log #{range} --pretty=format:"%s"`.split("\n")
  FastlaneCore::UI.message("Found #{commits.length} commits to process")

  filtered_commits = commits.reject { |c| c.match?(/^chore: Release v/i) }
  FastlaneCore::UI.message("#{filtered_commits.length} commits after filtering release commits")

  # === AI ENHANCEMENT ATTEMPT ===
  ai_result = nil
  if AIHelper.available?
    FastlaneCore::UI.message("Attempting AI-enhanced changelog generation...")
    ai_result = AIHelper.enhance_changelog(commits: filtered_commits, new_version: new_version)

    if ai_result
      FastlaneCore::UI.message("AI enhancement succeeded")
    else
      FastlaneCore::UI.important("AI enhancement returned no results, using template fallback")
    end
  else
    FastlaneCore::UI.message("ANTHROPIC_API_KEY not set, using template-based generation")
  end

  if ai_result
    added = ai_result[:added]
    changed = ai_result[:changed]
    fixed = ai_result[:fixed]
    removed = ai_result[:removed]
  else
    added = []
    changed = []
    fixed = []
    removed = []

    filtered_commits.each do |msg|
      case msg
      when /^feat(\(.+\))?:\s*(.+)/i
        added << $2.strip.capitalize
      when /^fix(\(.+\))?:\s*(.+)/i
        fixed << $2.strip.capitalize
      when /^(refactor|perf|style)(\(.+\))?:\s*(.+)/i
        changed << $3.strip.capitalize
      when /^(remove|revert)(\(.+\))?:\s*(.+)/i
        removed << $3.strip.capitalize
      when /^Add\s+(.+)/i
        added << $1.strip.capitalize
      when /^Fix\s+(.+)/i
        fixed << $1.strip.capitalize
      when /^(Update|Improve|Enhance|Refactor)\s+(.+)/i
        changed << $2.strip.capitalize
      when /^(Remove|Delete|Revert)\s+(.+)/i
        removed << $1.strip.capitalize
      end
    end
  end

  # Merge manual [Unreleased] notes into the appropriate buckets. Manual
  # entries come first so they read as the lead items in the changelog
  # section. "Improved" is a Keep-a-Changelog dialect that the existing
  # release-notes generator already understands — fold it into Changed.
  added   = (manual_sections['Added']   || []) + added
  changed = (manual_sections['Changed'] || []) + (manual_sections['Improved'] || []) + changed
  fixed   = (manual_sections['Fixed']   || []) + fixed
  removed = (manual_sections['Removed'] || []) + removed

  # Anything else the user wrote (Security, Deprecated, custom headers)
  # gets passed through to the new section verbatim, in original order.
  standard_headers = %w[Added Changed Fixed Removed Improved]
  extra_sections = manual_sections.reject { |header, _| standard_headers.include?(header) }

  added.uniq!
  changed.uniq!
  fixed.uniq!
  removed.uniq!

  # Bail out only if neither commits NOR manual notes produced anything.
  if added.empty? && changed.empty? && fixed.empty? && removed.empty? && extra_sections.empty?
    FastlaneCore::UI.important("No changelog entries derived from commits or [Unreleased] notes.")
    FastlaneCore::UI.important("Release notes will be left blank — add them manually in App Store Connect.")

    release_notes_path = File.join(Dir.pwd, 'metadata', 'en-US', 'release_notes.txt')
    File.write(release_notes_path, '') if File.exist?(release_notes_path)

    return false
  end

  date = Time.now.strftime("%Y-%m-%d")
  section = "## [#{new_version}] - #{date}\n"
  section += format_changelog_section("Added", added)
  section += format_changelog_section("Changed", changed)
  section += format_changelog_section("Fixed", fixed)
  section += format_changelog_section("Removed", removed)
  extra_sections.each do |header, items|
    section += format_changelog_section(header, items.uniq)
  end

  # Replace the [Unreleased] body with the empty Added/Changed/Fixed
  # skeleton followed by the new version section. Manual content has
  # already been merged into `section` above, so this reset is safe.
  unreleased_pattern = /## \[Unreleased\][^\n]*\n.*?(?=\n## \[|\n\[Unreleased\]:|\z)/m
  empty_skeleton = "## [Unreleased]\n\n### Added\n\n### Changed\n\n### Fixed\n"

  if content.match?(unreleased_pattern)
    new_content = content.sub(unreleased_pattern, "#{empty_skeleton}\n#{section}")
  else
    # No [Unreleased] block — insert one above the first version header.
    header_end = content.index("\n## [") || content.length
    new_content = content[0...header_end] + "\n\n#{empty_skeleton}\n#{section}" + content[header_end..-1].to_s
  end

  # Update footer links using the centralized REPO_URL from Constants.rb.
  # Patterns are anchored to start-of-line and use possessive [^\n]*+ to prevent
  # ReDoS on inputs with many repetitions of "[Unreleased]: ".
  new_content.gsub!(
    /^\[Unreleased\]: [^\n]*+/,
    "[Unreleased]: #{REPO_URL}/compare/v#{new_version}...HEAD"
  )

  version_link = "[#{new_version}]: #{REPO_URL}/compare/"
  unless new_content.include?(version_link)
    prev_version_match = new_content.match(/\[(\d+\.\d+\.\d+)\]: /)
    if prev_version_match
      prev_version = prev_version_match[1]
      new_link = "[#{new_version}]: #{REPO_URL}/compare/v#{prev_version}...v#{new_version}\n"
      new_content.sub!(/(^\[Unreleased\]: [^\n]*+\n)/, "\\1#{new_link}")
    else
      new_link = "[#{new_version}]: #{REPO_URL}/releases/tag/v#{new_version}\n"
      new_content.sub!(/(^\[Unreleased\]: [^\n]*+\n)/, "\\1#{new_link}")
    end
  end

  File.write(changelog_path, new_content)
  FastlaneCore::UI.message("CHANGELOG.md updated: #{new_version}")

  section
end

# Pre-flight: abort the lane immediately if v#{version} already exists as a
# tag locally or on origin. Local tags can leak in from a previous failed
# run; remote tags survive a `git tag -d` because git fetch will recreate
# them. Either way, the late `git tag -a` would crash and strand a release
# commit on local main.
def ensure_tag_available!(version:)
  tag = "v#{version}"

  if system("git rev-parse --verify --quiet refs/tags/#{tag} > /dev/null")
    FastlaneCore::UI.user_error!(
      "Tag #{tag} already exists locally. " \
      "Delete it (`git tag -d #{tag}`) and any orphan release commit on main " \
      "before retrying. If the remote also has the tag, also run " \
      "`git push origin :refs/tags/#{tag}` so it doesn't refetch."
    )
  end

  remote_ref = `git ls-remote origin refs/tags/#{tag} 2>/dev/null`.strip
  unless remote_ref.empty?
    FastlaneCore::UI.user_error!(
      "Tag #{tag} already exists on origin. " \
      "Delete it with `git push origin :refs/tags/#{tag}` before retrying " \
      "(or pick a different version)."
    )
  end
end

# Pre-flight: query App Store Connect to ensure the new version isn't
# already in use. App Store Connect rejects duplicate versionString values
# (even if the earlier upload was incomplete), and that rejection comes
# from `deliver` at the very end of the lane — after ~2 min of screenshots
# + archive, with the release commit and tag already pushed. Catching it
# here avoids the same expensive failure mode.
#
# Requires `app_store_connect_api_key` to have been called first so
# Spaceship is authenticated.
def ensure_version_available_on_app_store!(version:)
  require "spaceship"

  app = Spaceship::ConnectAPI::App.find(APP_IDENTIFIER)
  FastlaneCore::UI.user_error!("Could not find app '#{APP_IDENTIFIER}' on App Store Connect.") unless app

  existing = app.get_app_store_versions(filter: { versionString: version })
  return if existing.empty?

  # App Store Connect API migrated the version-status attribute from
  # appStoreState to appVersionState in 2024. Spaceship 2.233 still maps both,
  # but newer versions only populate app_version_state. Prefer the new name,
  # fall back to the legacy one, then to "unknown state" — without this
  # fallback chain a renamed-and-emptied field would silently mask the
  # actual ASC state behind a useless error message.
  record = existing.first
  state = record.app_version_state || record.app_store_state || "unknown state"
  FastlaneCore::UI.user_error!(
    "Version #{version} already exists on App Store Connect (state: #{state}). " \
    "App Store Connect rejects duplicate versionString values even when the " \
    "earlier upload was incomplete. Bump the marketing version higher than " \
    "#{version} before retrying, or remove the existing record on App Store " \
    "Connect."
  )
end

# Stage changelog/metadata/project edits and create the local release commit.
# Does NOT tag or push — see finalize_release for that. Splitting these lets
# the deploy lane gate the public-facing actions (tag + push) on a successful
# binary upload, so a failed `deliver` doesn't leave an orphan tag on origin.
def commit_release_local(version:)
  sh("git add ../CHANGELOG.md")
  sh("git add metadata/en-US/release_notes.txt")
  sh("git add ../LeavesOfBlocks.xcodeproj/project.pbxproj")

  # Bail out if there's nothing staged. Without this guard `git commit` would
  # exit non-zero, but `sh` would still raise — and the caller might mistake a
  # "nothing to commit" run for a partial success and run finalize_release.
  #
  # Note the project file is legitimately unchanged when a release ships the
  # version the project already states; the CHANGELOG and release notes are
  # what make this non-empty in that case.
  staged = sh("git diff --cached --name-only", log: false).strip
  if staged.empty?
    FastlaneCore::UI.user_error!(
      "No staged changes to commit for release v#{version}. " \
      "Did the version bump / changelog generation actually mutate disk? " \
      "Run `git status` to investigate."
    )
  end

  sh("git commit -m 'chore: Release v#{version}'")
  FastlaneCore::UI.success("Created local release commit for v#{version} (not yet pushed)")
end

# Is an executable of this name on PATH?
#
# A Ruby scan rather than `system("command -v ...")`: the gh invocation below
# deliberately avoids a shell, and this check should not quietly reintroduce
# one for the sake of a builtin.
def executable_in_path?(name)
  ENV.fetch('PATH', '').split(File::PATH_SEPARATOR).any? do |dir|
    next false if dir.empty?

    candidate = File.join(dir, name)
    File.file?(candidate) && File.executable?(candidate)
  end
end

# TestFlight's "What to Test" field. Apple caps it; truncate rather than let
# an upload be rejected for a field testers only skim.
TESTFLIGHT_NOTES_LIMIT = 4000

# Commit types worth showing a tester. A beta full of "chore: bump dependency"
# tells them nothing about what to exercise, and burying two real fixes among
# ten tooling commits is worse than showing neither.
TESTER_RELEVANT_TYPES = %w[feat fix perf refactor style revert].freeze

# Run a git command without a shell, returning empty on failure.
#
# stderr is captured and discarded rather than inherited. `git describe` on a
# repository with no tags writes "fatal: No names found, cannot describe
# anything" -- accurate, benign, and alarming to read in the middle of a
# release log for a case this code handles deliberately.
def _git_output(*args)
  require 'open3'
  out, _err, status = Open3.capture3('git', *args)
  status.success? ? out : ''
rescue StandardError
  ''
end

# Format a { heading => [items] } hash as plain text for TestFlight.
def format_testflight_notes(sections)
  return nil if sections.nil? || sections.empty?

  body = sections.map do |heading, items|
    next nil if items.nil? || items.empty?
    ([heading] + items.map { |item| "• #{item}" }).join("\n")
  end.compact

  body.empty? ? nil : body.join("\n\n")
end

# Format commit subjects as plain text, keeping only what a tester can act on.
# Conventional prefixes and the trailing PR number are stripped: "feat(grid):
# Add a hint button (#12)" reads as "Add a hint button".
def format_commit_notes(subjects)
  items = (subjects || []).map do |subject|
    match = subject.to_s.strip.match(/\A(\w+)(?:\([^)]*\))?!?:\s*(.+)\z/)
    next nil unless match && TESTER_RELEVANT_TYPES.include?(match[1].downcase)

    text = match[2].sub(/\s*\(#\d+\)\z/, '').strip
    text.empty? ? nil : "• #{text}"
  end.compact

  items.empty? ? nil : items.join("\n")
end

# Trim to TestFlight's limit, marking that something was cut so a tester does
# not read a sentence that stops mid-word and assume that is all there was.
def truncate_testflight_notes(text, limit: TESTFLIGHT_NOTES_LIMIT)
  return text if text.nil? || text.length <= limit

  marker = "\n\n… (truncated)"
  return text[0, limit] if limit <= marker.length

  text[0, limit - marker.length].rstrip + marker
end

# Build the "What to Test" text for a TestFlight upload.
#
# In order of preference: an explicit `notes:` lane argument, the CHANGELOG's
# [Unreleased] section, then tester-relevant commits since the last tag. The
# CHANGELOG comes first because it is written for humans and the release flow
# already depends on it being current; commits are the fallback that is always
# available.
#
# Never raises. Notes are a nicety and the upload is not: returning nil leaves
# the build without them, exactly as before this existed.
def testflight_notes(override: nil)
  candidate = override.to_s.strip
  return truncate_testflight_notes(candidate) unless candidate.empty?

  changelog_path = File.join(Dir.pwd, '..', 'CHANGELOG.md')
  if File.exist?(changelog_path)
    from_changelog = format_testflight_notes(_parse_unreleased_subsections(File.read(changelog_path)))
    return truncate_testflight_notes(from_changelog) if from_changelog
  end

  from_commits = format_commit_notes(commit_subjects_since_last_tag)
  return truncate_testflight_notes(from_commits) if from_commits

  FastlaneCore::UI.important("No [Unreleased] entries or tester-relevant commits — uploading without notes.")
  nil
rescue StandardError => e
  FastlaneCore::UI.important("Could not build TestFlight notes (#{e.message}); uploading without them.")
  nil
end

# Subjects of non-merge commits since the most recent tag, or every commit when
# the repository has no tags yet.
#
# The no-tag case omits the range rather than substituting a sentinel revision.
# An earlier version passed the empty-tree hash so that "#{ref}..HEAD" always
# had a left side; git happens to tolerate a tree there and returns the full
# history, but that is incidental rather than documented -- `A..B` means
# `B ^A`, and A is meant to be a commit. It also disagreed with
# update_changelog_from_commits, which drops the range in the same situation.
# Two functions reading the same history should not differ on how they ask.
def commit_subjects_since_last_tag
  tag = _git_output('describe', '--tags', '--abbrev=0').strip

  args = ['log', '--no-merges', '--format=%s']
  args.insert(1, "#{tag}..HEAD") unless tag.empty?

  _git_output(*args).split("\n").map(&:strip).reject(&:empty?)
end

# Compare what App Store Connect ended up with against what was sent.
#
# fastlane 2.238.0 uploaded every screenshot twice (#97): App Store Connect
# publishes a screenshot's checksum asynchronously after its state reaches
# COMPLETE, fastlane read the nil checksum as "not uploaded" and sent them
# again. Version 2.0.7 went to review showing 8 screenshots where there are 4,
# and nothing in this pipeline noticed -- the upload reported success.
#
# Warns rather than raises. It runs after deliver, so the binary and metadata
# are already up; a mismatch is something to go and fix in App Store Connect,
# not a reason to report the release as failed.
def verify_uploaded_screenshots
  # Resolved through project_root, not Dir.pwd. fastlane runs with Dir.pwd at
  # either the repo root or fastlane/, so a hardcoded relative glob finds
  # nothing from the root -- and this method returns early on an empty result,
  # so it would have reported nothing and looked like it had checked. A
  # verifier that silently no-ops is worse than no verifier: the run stays
  # green either way, and only one of those means the listing is correct.
  root = project_root(File.join('fastlane', 'screenshots'))
  unless root
    FastlaneCore::UI.important("Could not locate fastlane/screenshots; skipping screenshot verification.")
    return
  end

  local_by_locale = Hash.new(0)
  Dir.glob(File.join(root, 'fastlane', 'screenshots', '*', '*.png')).each do |path|
    next if path.include?('/framed/')
    local_by_locale[File.basename(File.dirname(path))] += 1
  end

  if local_by_locale.empty?
    FastlaneCore::UI.important("No local screenshots found; nothing to verify against.")
    return
  end

  app = Spaceship::ConnectAPI::App.find(APP_IDENTIFIER)
  version = app.get_edit_app_store_version
  return unless version

  mismatches = []
  version.get_app_store_version_localizations.each do |loc|
    remote = loc.get_app_screenshot_sets.sum { |set| (set.app_screenshots || []).count }
    expected = local_by_locale[loc.locale]
    next if expected.zero?

    if remote == expected
      FastlaneCore::UI.message("Screenshots for #{loc.locale}: #{remote}, as sent")
    else
      mismatches << "#{loc.locale}: App Store Connect has #{remote}, #{expected} were sent"
    end
  end

  return if mismatches.empty?

  FastlaneCore::UI.important("Screenshot count mismatch — check the listing before the version is reviewed:")
  mismatches.each { |m| FastlaneCore::UI.important("  #{m}") }
  FastlaneCore::UI.important("`fastlane ios screenshots_only` replaces the set.")
rescue StandardError => e
  FastlaneCore::UI.important("Could not verify screenshot counts (#{e.message}); check the listing by hand.")
end

# Publish a GitHub Release for a tag that has already been pushed.
#
# Named for exactly what shipped: the tag is v<version>, the notes are that
# version's CHANGELOG section, and the build number that went to App Store
# Connect is recorded in the body. One version string identifies the App Store
# submission, the git tag and the GitHub Release.
#
# Soft-fails by design. This runs after deliver has succeeded and the tag is
# already public, so the release is done whatever happens here. A missing `gh`
# or a transient API error should leave a warning and a one-line manual fix,
# not fail a lane whose binary is already on App Store Connect.
def publish_github_release(version:, build_number: nil)
  tag = "v#{version}"

  unless executable_in_path?('gh')
    FastlaneCore::UI.important("gh not found — skipping GitHub Release for #{tag}.")
    FastlaneCore::UI.important("Create it later with: gh release create #{tag} --title #{tag} --notes-file <file>")
    return false
  end

  changelog_path = File.join(Dir.pwd, '..', 'CHANGELOG.md')
  notes = File.exist?(changelog_path) ? extract_changelog_section(File.read(changelog_path), version) : nil

  if notes.nil?
    FastlaneCore::UI.important("No CHANGELOG section for #{version} — skipping GitHub Release.")
    return false
  end

  notes += "\n\nApp Store build: #{version} (#{build_number})" if build_number

  require 'tempfile'
  file = Tempfile.new(['release-notes', '.md'])
  begin
    file.write(notes)
    file.close

    # Array form: no shell, so nothing in the notes path or tag is interpreted.
    if system('gh', 'release', 'create', tag, '--title', tag, '--notes-file', file.path)
      FastlaneCore::UI.success("Published GitHub Release #{tag}")
      true
    else
      FastlaneCore::UI.important("Could not publish GitHub Release #{tag} — the release itself is unaffected.")
      FastlaneCore::UI.important("Retry with: gh release create #{tag} --title #{tag} --notes-file <file>")
      false
    end
  ensure
    file.unlink
  end
end

# Tag the commit at HEAD and push commit + tag to origin/main. Run ONLY after
# the binary upload (deliver) has succeeded — otherwise a failed upload
# strands a public tag pointing at a release that never shipped.
def finalize_release(version:, build_number: nil)
  # Defensive: tag must attach to the release commit we just made.
  head_subject = sh("git log -1 --pretty=%s", log: false).strip
  expected = "chore: Release v#{version}"
  unless head_subject == expected
    FastlaneCore::UI.user_error!(
      "Refusing to tag: HEAD commit subject is '#{head_subject}', expected '#{expected}'. " \
      "The release commit appears to be missing or out of order — investigate before retrying."
    )
  end

  sh("git tag -a v#{version} -m 'Release version #{version}'")
  sh("git push origin main")
  sh("git push origin v#{version}")

  FastlaneCore::UI.success("Tagged and pushed v#{version}")

  # After the tag exists on origin, so `gh release create` attaches to it
  # rather than creating one. Soft-fails; see publish_github_release.
  publish_github_release(version: version, build_number: build_number)
end

# ─────────────────────────────────────────────────────────────────────────────
# Release preflight
#
# Every read-only check the release path depends on, run together and reported
# as one table. Nothing here writes to the repository, the project file, or App
# Store Connect.
#
# It exists because the release pipeline changed substantially without ever
# running: build numbers from App Store Connect, the Xcode floor, phased
# rollout, the GitHub Release step, TestFlight notes and the derived simulator
# runtime all had their first live exercise scheduled for a real release. This
# moves the discoverable half of that somewhere failure is free.
#
# What it deliberately cannot cover: signing, archiving, upload, submission,
# phased rollout, and the gh call itself. Those still first run for real. Run
# `beta` before `deploy` so signing and the archive are exercised against
# TestFlight rather than the App Store.
# ─────────────────────────────────────────────────────────────────────────────

# One row of the report. A failing check is recorded rather than raised, so a
# single problem does not hide the others -- learning that three things are
# wrong beats fixing them one run at a time.
def _preflight(rows, name, severity: :fail)
  value = yield
  if value.nil? || (value.respond_to?(:empty?) && value.empty?)
    rows << [name, severity, 'not available']
  else
    rows << [name, :ok, value.to_s]
  end
rescue StandardError => e
  rows << [name, severity, e.message.to_s.lines.first.to_s.strip]
end

def run_release_preflight(api_key:, bump_type:)
  rows = []

  _preflight(rows, 'Xcode meets minimum') do
    require 'shellwords'
    ensure_minimum_xcode_version!

    # Resolved the same way ensure_minimum_xcode_version! does. A hardcoded
    # "../scripts" points outside the repository when fastlane runs from the
    # root, which would fail this row while Xcode was perfectly fine -- a
    # preflight that invents failures is worse than one that does not exist.
    root = project_root(File.join('scripts', 'xcode-version.sh'))
    raise 'could not locate scripts/xcode-version.sh' unless root

    script = File.join(root, 'scripts', 'xcode-version.sh')
    "#{`#{script.shellescape} --min`.strip} or newer"
  end

  _preflight(rows, 'Working tree clean') do
    _git_output('status', '--porcelain').strip.empty? ? 'clean' : (raise 'uncommitted changes present')
  end

  _preflight(rows, 'On main') do
    branch = _git_output('rev-parse', '--abbrev-ref', 'HEAD').strip
    branch == 'main' ? branch : (raise "on '#{branch}', release requires main")
  end

  _preflight(rows, 'Simulator runtime') do
    simulator_runtime_version
  end

  _preflight(rows, 'App Store Connect auth') do
    latest = next_build_number(api_key: api_key)
    "reachable, next build #{latest}"
  end

  # Mirrors _release_core: with no bump_type a release ships the version the
  # project already states. Previewing a patch bump instead would show a target
  # the deploy would not actually use.
  target_version = nil
  _preflight(rows, 'Target version') do
    current = read_marketing_version(xcodeproj: XCODE_PROJECT, target_name: MAIN_SCHEME)
    target_version = _resolve_target_version(current: current, bump_type: bump_type)
    target_version == current ? "#{current} (as the project states)" : "#{current} -> #{target_version}"
  end

  _preflight(rows, 'Tag available') do
    raise 'target version unresolved' unless target_version
    ensure_tag_available!(version: target_version)
    "v#{target_version} is free"
  end

  _preflight(rows, 'Version free on ASC') do
    raise 'target version unresolved' unless target_version
    ensure_version_available_on_app_store!(version: target_version)
    "#{target_version} not yet used"
  end

  # The row whose absence let #95 through. The checks above validate the version
  # a future `deploy` would ship; a `beta` uploads under the version the project
  # states right now, and App Store Connect refuses builds under an approved
  # one. Passing preflight and then failing an upload it could have predicted is
  # worse than no preflight, because the green result is what convinced you to
  # run it.
  _preflight(rows, 'TestFlight accepts current version') do
    current = read_marketing_version(xcodeproj: XCODE_PROJECT, target_name: MAIN_SCHEME)
    ensure_version_available_on_app_store!(version: current)
    "#{current} can still take builds"
  rescue StandardError
    raise "#{read_marketing_version(xcodeproj: XCODE_PROJECT, target_name: MAIN_SCHEME)} is already released; " \
          "beta will be refused until the project moves to the next version"
  end

  _preflight(rows, 'CHANGELOG section') do
    raise 'target version unresolved' unless target_version
    path = File.join(Dir.pwd, '..', 'CHANGELOG.md')
    section = File.exist?(path) ? extract_changelog_section(File.read(path), 'Unreleased') : nil
    section ? "#{section.lines.count} line(s) under [Unreleased]" : (raise '[Unreleased] is empty; the release would have no notes')
  end

  _preflight(rows, 'TestFlight notes') do
    notes = testflight_notes
    notes ? "#{notes.length} chars" : nil
  end

  # gh only warns: publish_github_release soft-fails by design, so its absence
  # must not read as a blocked release.
  _preflight(rows, 'gh for GitHub Release', severity: :warn) do
    executable_in_path?('gh') ? 'present' : nil
  end

  width = rows.map { |r| r[0].length }.max
  FastlaneCore::UI.message('')
  rows.each do |name, status, detail|
    icon = { ok: '✓', warn: '!', fail: '✗' }[status]
    line = format("  %s  %-#{width}s  %s", icon, name, detail)
    case status
    when :ok   then FastlaneCore::UI.success(line)
    when :warn then FastlaneCore::UI.important(line)
    else            FastlaneCore::UI.error(line)
    end
  end
  FastlaneCore::UI.message('')

  failures = rows.count { |r| r[1] == :fail }
  warnings = rows.count { |r| r[1] == :warn }

  if failures.positive?
    FastlaneCore::UI.user_error!("Preflight failed: #{failures} check(s) would block a release.")
  end

  FastlaneCore::UI.success("Preflight passed#{warnings.positive? ? " with #{warnings} warning(s)" : ''}.")
  FastlaneCore::UI.important('Not covered: signing, archive, upload, submission, phased rollout.')
  FastlaneCore::UI.important('Run `beta` before `deploy` to exercise those against TestFlight first.')
  rows
end

# Move the project onto the next development version after a release.
#
# Runs AFTER the tag is pushed, deliberately. The tag must point at a commit
# where MARKETING_VERSION states the version that shipped -- that is the
# traceability #63 established, and bumping before tagging would break it.
#
# Why bump at all: App Store Connect refuses further builds under an approved
# version. Left at the just-shipped number, the project makes `beta` unusable
# from approval until the next release. Moving to the next patch immediately
# means TestFlight builds during development go out as X.Y.Z+1 (n), which is
# also what the next `deploy` will ship.
#
# Soft-fails. The release is already public by this point; a push failure here
# is a chore to finish by hand, not a reason to report the release as failed.
def begin_next_development_version(shipped_version:)
  next_version = _resolve_bump(current: shipped_version, bump_type: 'patch')

  bump_marketing_version(
    xcodeproj: XCODE_PROJECT,
    target_name: MAIN_SCHEME,
    version: next_version
  )

  sh("git add ../LeavesOfBlocks.xcodeproj/project.pbxproj")
  sh("git commit -m 'chore: Begin development on v#{next_version}'")
  sh("git push origin main")

  FastlaneCore::UI.success("Project moved to v#{next_version} for development")
  next_version
rescue StandardError => e
  FastlaneCore::UI.important("Could not move the project to the next version: #{e.message}")
  FastlaneCore::UI.important("The release itself is unaffected. Finish by hand, or `beta` will be")
  FastlaneCore::UI.important("refused until it is done:")
  FastlaneCore::UI.important("  set MARKETING_VERSION to the next patch, commit, push")
  nil
end

# Canonical release flow shared by `deploy` and `deploy_and_submit`. The
# only behavioral difference between those two lanes is the value of
# `submit:` passed through to `deliver`.
#
# Order is structured so that:
#   - All cheap remote validations run before any disk mutation.
#   - Screenshot capture (UI tests, occasionally flaky) runs before disk
#     mutation, so a flaky run doesn't strand a CHANGELOG/version bump.
#   - Local commit happens before archive/upload, so if archive or deliver
#     fails we have one local commit to undo (`git reset --hard HEAD~1`)
#     instead of an orphan tag pushed to origin.
#   - Tag + push to origin happen ONLY after deliver returns success.
def _release_core(api_key:, options:, submit:)
  FastlaneCore::UI.message("▸ Pre-flight: git status + branch")
  ensure_git_status_clean
  ensure_git_branch(branch: 'main')

  # MARKETING_VERSION states the version under development, so a release ships
  # what the project already says. `version:` is only needed to change train --
  # minor, major, or an explicit number -- and is applied before shipping.
  #
  # It used to be required and always bumped at release time, which left the
  # project sitting at the just-shipped version between releases. App Store
  # Connect refuses further builds under an approved version, so `beta` was
  # unusable from the moment a release was approved until the next deploy --
  # exactly when a TestFlight build is most wanted. See #95.
  FastlaneCore::UI.message("▸ Resolving target version")
  new_version = _resolve_target_version(
    current: read_marketing_version(xcodeproj: XCODE_PROJECT, target_name: MAIN_SCHEME),
    bump_type: options[:version]
  )
  FastlaneCore::UI.message("Target version: #{new_version}")

  FastlaneCore::UI.message("▸ Verifying tag availability (local + origin)")
  ensure_tag_available!(version: new_version)

  FastlaneCore::UI.message("▸ Verifying version availability on App Store Connect")
  ensure_version_available_on_app_store!(version: new_version)

  # Screenshots before disk mutations — UI tests are flaky enough that we'd
  # rather find out before bumping CHANGELOG/version.
  FastlaneCore::UI.message("▸ Capturing screenshots")
  build_for_testing
  capture_screenshots(
    number_of_retries: 0,
    only_testing: ["LeavesOfBlocksUITests/LeavesOfBlocksUITests/testCaptureScreenshots"]
  )

  FastlaneCore::UI.message("▸ Updating changelog from commits")
  changelog_updated = update_changelog_from_commits(new_version: new_version)

  # new_version, resolved once above, is the single identity for this release:
  # the project's MARKETING_VERSION, the App Store submission, the git tag and
  # the GitHub Release all carry it. Passing it explicitly (rather than
  # re-deriving it from the bump type here) removes the second, independent
  # computation that could disagree with the first.
  FastlaneCore::UI.message("▸ Setting marketing version")
  bump_marketing_version(
    xcodeproj: XCODE_PROJECT,
    target_name: MAIN_SCHEME,
    version: new_version
  )

  if changelog_updated
    FastlaneCore::UI.message("▸ Generating release notes")
    generate_release_notes(version: new_version)
  end

  # Local commit only. If anything below fails, recovery is one
  # `git reset --hard HEAD~1` — no public artifacts created yet.
  FastlaneCore::UI.message("▸ Creating local release commit")
  commit_release_local(version: new_version)

  # Build number is resolved from App Store Connect here, not from the project
  # file -- so the release commit above carries only the marketing version and
  # changelog, and a re-run after a failed archive picks the next free number
  # rather than reusing one. Resolved once and reused, so the number recorded
  # in the GitHub Release is the number that was actually built.
  FastlaneCore::UI.message("▸ Archiving")
  build_number = next_build_number(api_key: api_key)
  app_store_build_app(api_key: api_key, build_number: build_number)

  FastlaneCore::UI.message("▸ Uploading to App Store Connect")
  deliver(
    api_key: api_key,
    submit_for_review: submit,
    automatic_release: false,
    force: true,
    skip_metadata: false,
    skip_screenshots: false
  )
  FastlaneCore::UI.success("Delivered to App Store Connect")

  FastlaneCore::UI.message("▸ Verifying uploaded screenshots")
  verify_uploaded_screenshots

  # Point of no return passed: tag + push to origin.
  FastlaneCore::UI.message("▸ Finalizing release (tag + push + GitHub Release)")
  finalize_release(version: new_version, build_number: build_number)

  # After the tag, never before: see begin_next_development_version.
  FastlaneCore::UI.message("▸ Opening the next development version")
  next_version = begin_next_development_version(shipped_version: new_version)

  # Lane-level summary. Emoji used as semantic icons here, not decoration:
  # 📱 binary state, 🏷️ git tag state, ⏳ what to wait for next.
  FastlaneCore::UI.success(submit ? "🎉 Release deployed and submitted for review" : "Release deployed")
  FastlaneCore::UI.message("📱 Binary, metadata, and screenshots uploaded")
  FastlaneCore::UI.message("🏷️  Git tag v#{new_version} pushed to origin, GitHub Release published")
  FastlaneCore::UI.message("🔜 Project now on v#{next_version} for development") if next_version
  FastlaneCore::UI.message(submit ? "⏳ Apple will review within 24-48 hours" : "⏳ Check App Store Connect for build processing")

  new_version
end
