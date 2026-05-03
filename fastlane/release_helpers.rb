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
    UI.user_error!(
      "Invalid version bump '#{bump_type}'. Expected one of: " \
      "'patch', 'minor', 'major', or a semver string like '1.2.3'."
    )
  end
end

# Bump MARKETING_VERSION directly via the xcodeproj gem.
# Works around `increment_version_number` failing under
# GENERATE_INFOPLIST_FILE=YES (it tries to update an Info.plist that doesn't
# exist as a file, aborts before persisting the project setting, and
# silently leaves the old version on the build).
def bump_marketing_version(xcodeproj:, target_name:, bump_type:)
  require 'xcodeproj'

  # Fastlane runs from fastlane/, so go up one level to reach the project.
  project_path = File.join(Dir.pwd, '..', xcodeproj)
  project = Xcodeproj::Project.open(project_path)

  target = project.targets.find { |t| t.name == target_name }
  UI.user_error!("Target '#{target_name}' not found") unless target

  release_config = target.build_configurations.find { |c| c.name == 'Release' }
  current_version = release_config.build_settings['MARKETING_VERSION'] || '1.0.0'

  UI.message("Current version: #{current_version}")
  new_version = _resolve_bump(current: current_version, bump_type: bump_type)

  target.build_configurations.each do |config|
    config.build_settings['MARKETING_VERSION'] = new_version
  end
  project.save

  UI.message("Version bumped: #{current_version} → #{new_version}")
  new_version
end

# Calculate the new MARKETING_VERSION without applying it. Used pre-flight
# so we know the target version before mutating any disk state.
def calculate_new_version(xcodeproj:, target_name:, bump_type:)
  require 'xcodeproj'

  project_path = File.join(Dir.pwd, '..', xcodeproj)
  project = Xcodeproj::Project.open(project_path)

  target = project.targets.find { |t| t.name == target_name }
  UI.user_error!("Target '#{target_name}' not found") unless target

  release_config = target.build_configurations.find { |c| c.name == 'Release' }
  current_version = release_config.build_settings['MARKETING_VERSION'] || '1.0.0'

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

  # Each subsection is "### Header\n" followed by zero or more bullet lines,
  # ending at the next "### " or end-of-block.
  body.scan(/### (\w+)\s*\n(.*?)(?=\n### |\z)/m) do |header, items_block|
    bullets = items_block.scan(/^- (.+)$/).flatten.map(&:strip).reject(&:empty?)
    sections[header] = bullets unless bullets.empty?
  end

  sections
end

# Generate App Store release notes from CHANGELOG.md, preferring AI prose
# when ANTHROPIC_API_KEY is configured and falling back to a template.
def generate_release_notes(version:)
  changelog_path = File.join(Dir.pwd, '..', 'CHANGELOG.md')
  release_notes_path = File.join(Dir.pwd, 'metadata', 'en-US', 'release_notes.txt')

  unless File.exist?(changelog_path)
    UI.important("CHANGELOG.md not found, skipping release notes generation")
    return nil
  end

  content = File.read(changelog_path)

  # Try to find the section for this version, or fall back to [Unreleased].
  version_pattern = /## \[#{Regexp.escape(version)}\].*?\n(.*?)(?=\n## \[|\n\[Unreleased\]:|\z)/m
  unreleased_pattern = /## \[Unreleased\].*?\n(.*?)(?=\n## \[|\z)/m

  section = content.match(version_pattern)
  section = content.match(unreleased_pattern) if section.nil? || section[1].strip.empty?

  if section.nil? || section[1].strip.empty?
    UI.important("No changelog entries found for version #{version}")
    return nil
  end

  section_content = section[1]

  # === AI PROSE GENERATION ATTEMPT ===
  prose = nil
  if AIHelper.available?
    UI.message("Attempting AI-generated release notes...")
    prose = AIHelper.generate_prose(changelog_section: section_content, version: version)

    if prose
      UI.message("AI prose generation succeeded")
    else
      UI.important("AI prose generation returned no results, using template fallback")
    end
  else
    UI.message("ANTHROPIC_API_KEY not set, using template-based release notes")
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
  UI.message("Release notes generated: #{version}")
  UI.message("Preview:\n#{prose}")

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
    UI.user_error!("CHANGELOG.md not found at #{changelog_path}")
  end
  content = File.read(changelog_path)

  # Manual notes the maintainer added under [Unreleased] are extracted up
  # front. They get carried into the new release section so they aren't
  # silently dropped when [Unreleased] is reset. Custom subsections like
  # Security or Improved are preserved verbatim.
  manual_sections = _parse_unreleased_subsections(content)
  if manual_sections.any?
    summary = manual_sections.transform_values(&:length)
    UI.important("Carrying over manual [Unreleased] entries: #{summary.inspect}")
  end

  last_tag = `git describe --tags --abbrev=0 2>/dev/null`.strip

  if last_tag.empty?
    UI.message("No previous tags found, using all commits")
    range = ""
  else
    UI.message("Finding commits since #{last_tag}")
    range = "#{last_tag}..HEAD"
  end

  commits = `git log #{range} --pretty=format:"%s"`.split("\n")
  UI.message("Found #{commits.length} commits to process")

  filtered_commits = commits.reject { |c| c.match?(/^chore: Release v/i) }
  UI.message("#{filtered_commits.length} commits after filtering release commits")

  # === AI ENHANCEMENT ATTEMPT ===
  ai_result = nil
  if AIHelper.available?
    UI.message("Attempting AI-enhanced changelog generation...")
    ai_result = AIHelper.enhance_changelog(commits: filtered_commits, new_version: new_version)

    if ai_result
      UI.message("AI enhancement succeeded")
    else
      UI.important("AI enhancement returned no results, using template fallback")
    end
  else
    UI.message("ANTHROPIC_API_KEY not set, using template-based generation")
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
    UI.important("No changelog entries derived from commits or [Unreleased] notes.")
    UI.important("Release notes will be left blank — add them manually in App Store Connect.")

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
  UI.message("CHANGELOG.md updated: #{new_version}")

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
    UI.user_error!(
      "Tag #{tag} already exists locally. " \
      "Delete it (`git tag -d #{tag}`) and any orphan release commit on main " \
      "before retrying. If the remote also has the tag, also run " \
      "`git push origin :refs/tags/#{tag}` so it doesn't refetch."
    )
  end

  remote_ref = `git ls-remote origin refs/tags/#{tag} 2>/dev/null`.strip
  unless remote_ref.empty?
    UI.user_error!(
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
  UI.user_error!("Could not find app '#{APP_IDENTIFIER}' on App Store Connect.") unless app

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
  UI.user_error!(
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
  staged = sh("git diff --cached --name-only", log: false).strip
  if staged.empty?
    UI.user_error!(
      "No staged changes to commit for release v#{version}. " \
      "Did the version bump / changelog generation actually mutate disk? " \
      "Run `git status` to investigate."
    )
  end

  sh("git commit -m 'chore: Release v#{version}'")
  UI.success("Created local release commit for v#{version} (not yet pushed)")
end

# Tag the commit at HEAD and push commit + tag to origin/main. Run ONLY after
# the binary upload (deliver) has succeeded — otherwise a failed upload
# strands a public tag pointing at a release that never shipped.
def finalize_release(version:)
  # Defensive: tag must attach to the release commit we just made.
  head_subject = sh("git log -1 --pretty=%s", log: false).strip
  expected = "chore: Release v#{version}"
  unless head_subject == expected
    UI.user_error!(
      "Refusing to tag: HEAD commit subject is '#{head_subject}', expected '#{expected}'. " \
      "The release commit appears to be missing or out of order — investigate before retrying."
    )
  end

  sh("git tag -a v#{version} -m 'Release version #{version}'")
  sh("git push origin main")
  sh("git push origin v#{version}")

  UI.success("Tagged and pushed v#{version}")
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
  unless options[:version]
    lane_name = submit ? 'deploy_and_submit' : 'deploy'
    UI.user_error!("Version bump required. Use: fastlane #{lane_name} version:patch|minor|major")
  end

  UI.message("▸ Pre-flight: git status + branch")
  ensure_git_status_clean
  ensure_git_branch(branch: 'main')

  UI.message("▸ Resolving target version")
  new_version = calculate_new_version(
    xcodeproj: XCODE_PROJECT,
    target_name: MAIN_SCHEME,
    bump_type: options[:version]
  )
  UI.message("Target version: #{new_version}")

  UI.message("▸ Verifying tag availability (local + origin)")
  ensure_tag_available!(version: new_version)

  UI.message("▸ Verifying version availability on App Store Connect")
  ensure_version_available_on_app_store!(version: new_version)

  # Screenshots before disk mutations — UI tests are flaky enough that we'd
  # rather find out before bumping CHANGELOG/version.
  UI.message("▸ Capturing screenshots")
  build_for_testing
  capture_screenshots(
    number_of_retries: 0,
    only_testing: ["LeavesOfBlocksUITests/LeavesOfBlocksUITests/testCaptureScreenshots"]
  )

  UI.message("▸ Updating changelog from commits")
  changelog_updated = update_changelog_from_commits(new_version: new_version)

  UI.message("▸ Bumping marketing version + build number")
  bump_marketing_version(
    xcodeproj: XCODE_PROJECT,
    target_name: MAIN_SCHEME,
    bump_type: options[:version]
  )
  increment_build_number(xcodeproj: XCODE_PROJECT)

  if changelog_updated
    UI.message("▸ Generating release notes")
    generate_release_notes(version: new_version)
  end

  # Local commit only. If anything below fails, recovery is one
  # `git reset --hard HEAD~1` — no public artifacts created yet.
  UI.message("▸ Creating local release commit")
  commit_release_local(version: new_version)

  UI.message("▸ Archiving")
  build_app(
    project: XCODE_PROJECT,
    scheme: MAIN_SCHEME,
    export_method: EXPORT_METHOD,
    export_options: app_store_signing_options(api_key: api_key)
  )

  UI.message("▸ Uploading to App Store Connect")
  deliver(
    api_key: api_key,
    submit_for_review: submit,
    automatic_release: false,
    force: true,
    skip_metadata: false,
    skip_screenshots: false
  )
  UI.success("Delivered to App Store Connect")

  # Point of no return passed: tag + push to origin.
  UI.message("▸ Finalizing release (tag + push)")
  finalize_release(version: new_version)

  # Lane-level summary. Emoji used as semantic icons here, not decoration:
  # 📱 binary state, 🏷️ git tag state, ⏳ what to wait for next.
  UI.success(submit ? "🎉 Release deployed and submitted for review" : "Release deployed")
  UI.message("📱 Binary, metadata, and screenshots uploaded")
  UI.message("🏷️  Git tag v#{new_version} pushed to origin")
  UI.message(submit ? "⏳ Apple will review within 24-48 hours" : "⏳ Check App Store Connect for build processing")

  new_version
end
