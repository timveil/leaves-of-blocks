#!/usr/bin/env ruby
#
# release_helpers_test.rb - Exercise the pure functions in release_helpers.rb.
#
# No framework: minitest is a bundled rather than default gem, and adding a
# dependency to test two regexes is a poor trade. This matches the hand-rolled
# style of the shell suites in scripts/.
#
# Only functions that touch neither the network nor a real Xcode project are
# covered here -- the regex-driven ones, where a subtle mistake is silent and
# expensive: a changelog section that swallows the link footer, or a version
# bump that resolves to the wrong number and tags a release accordingly.
#
#   ruby fastlane/test/release_helpers_test.rb

# release_helpers.rb calls FastlaneCore::UI for reporting and for aborting.
# Stub it so the error paths can be exercised outside a lane.
module FastlaneCore
  class UserError < StandardError; end

  module UI
    def self.message(_msg); end
    def self.success(_msg); end
    def self.important(_msg); end
    def self.user_error!(msg)
      raise UserError, msg
    end
  end
end

# generate_release_notes reaches for AIHelper when ANTHROPIC_API_KEY is set.
# Stubbed so the paths through it run deterministically, offline, and without
# spending tokens to assert which file gets which language.
module AIHelper
  class << self
    attr_accessor :stub_available, :stub_prose, :locales_asked

    def available?
      stub_available
    end

    def generate_prose(changelog_section:, version:, locale: nil)
      locales_asked << locale
      stub_prose.respond_to?(:call) ? stub_prose.call(locale) : stub_prose
    end

    def reset!(available: false, prose: nil)
      self.stub_available = available
      self.stub_prose = prose
      self.locales_asked = []
    end
  end
end
AIHelper.reset!

require 'tmpdir'
require 'fileutils'
require 'open3'
require 'json'

# app_store_edit_version is the one network helper covered here, because the way
# it reports failure decides whether preflight can be trusted. Spaceship comes
# from fastlane at lane time and is not loaded in this suite, so App.find is
# stubbed down to the three outcomes that matter.
APP_IDENTIFIER = 'timothy.veil.LeavesOfBlocks' unless defined?(APP_IDENTIFIER)

module Spaceship
  module ConnectAPI
    class StubEditVersion
      attr_reader :version_string, :app_store_state

      def initialize(version_string, app_store_state)
        @version_string = version_string
        @app_store_state = app_store_state
      end
    end

    class App
      class << self
        attr_accessor :stub_edit, :stub_in_review, :stub_pending_release, :stub_error

        def find(_identifier)
          raise stub_error if stub_error

          new
        end

        def reset_stubs!
          self.stub_edit = nil
          self.stub_in_review = nil
          self.stub_pending_release = nil
          self.stub_error = nil
        end
      end

      # Three accessors, three disjoint state filters. Spaceship splits them
      # this way, and asking only the first is what let a version in review
      # look like an empty slot.
      def get_edit_app_store_version(*)
        self.class.stub_edit
      end

      def get_in_review_app_store_version(*)
        self.class.stub_in_review
      end

      def get_pending_release_app_store_version(*)
        self.class.stub_pending_release
      end
    end
  end
end

require_relative '../release_helpers'

$pass = 0
$fail = 0

def ok(desc)
  $pass += 1
  puts "  ok    #{desc}"
end

def bad(desc, detail)
  $fail += 1
  puts "  FAIL  #{desc}"
  puts "        #{detail}"
end

def assert_equal(expected, actual, desc)
  if expected == actual
    ok(desc)
  else
    bad(desc, "expected #{expected.inspect}, got #{actual.inspect}")
  end
end

def assert_raises(desc)
  yield
  bad(desc, "expected an error, none raised")
rescue FastlaneCore::UserError
  ok(desc)
rescue StandardError => e
  bad(desc, "expected FastlaneCore::UserError, got #{e.class}: #{e.message}")
end

CHANGELOG = <<~MD
  # Changelog

  ## [Unreleased]

  ### Added
  - Something pending

  ## [2.0.6] - 2026-06-20

  ### Added
  - Undo and Hint assists

  ### Fixed
  - Taper drag lift near the top of the board

  ## [2.0.5] - 2026-05-17

  ### Added
  - Background audio mixing

  ## [1.0] - 2026-01-01

  ### Added
  - First release

  [Unreleased]: https://github.com/timveil/leaves-of-blocks/compare/v2.0.6...HEAD
  [2.0.6]: https://github.com/timveil/leaves-of-blocks/compare/v2.0.5...v2.0.6
MD

puts "extract_changelog_section"

section = extract_changelog_section(CHANGELOG, '2.0.6')
assert_equal(true, section.start_with?('### Added'), "starts at the first subsection")
assert_equal(true, section.include?('Undo and Hint assists'), "includes its own items")
assert_equal(false, section.include?('Background audio'), "stops before the next version")
assert_equal(false, section.include?('## ['), "does not include the next heading")

# The last section is the one that can run away to end of file. Without the
# link-footer terminator it swallows the whole compare-link block, which would
# then appear verbatim in the GitHub Release body.
last = extract_changelog_section(CHANGELOG, '1.0')
assert_equal(true, last.include?('First release'), "the final section is extracted")
assert_equal(false, last.include?('[Unreleased]:'), "the final section stops at the link footer")
assert_equal(false, last.include?('https://'), "no compare links leak into the notes")

unreleased = extract_changelog_section(CHANGELOG, 'Unreleased')
assert_equal(true, unreleased.include?('Something pending'), "[Unreleased] is extractable")

assert_equal(nil, extract_changelog_section(CHANGELOG, '9.9.9'), "an absent version returns nil")

empty = "# Changelog\n\n## [3.0.0] - 2026-09-01\n\n## [2.0.0] - 2026-01-01\n\n### Added\n- Thing\n"
assert_equal(nil, extract_changelog_section(empty, '3.0.0'), "an empty section returns nil")

# The version is interpolated into a regex, so "1.0" must not match "1x0".
dotted = "## [1x0] - 2026-01-01\n\n### Added\n- Wrong section\n"
assert_equal(nil, extract_changelog_section(dotted, '1.0'), "the dot in a version is not a wildcard")

# Trailing whitespace would show up as blank lines at the end of the release body.
assert_equal(section, section.strip, "the result is trimmed")

puts
puts "_resolve_bump"

assert_equal('2.0.7', _resolve_bump(current: '2.0.6', bump_type: 'patch'), "patch bumps the third component")
assert_equal('2.1.0', _resolve_bump(current: '2.0.6', bump_type: 'minor'), "minor resets patch")
assert_equal('3.0.0', _resolve_bump(current: '2.0.6', bump_type: 'major'), "major resets minor and patch")
assert_equal('4.5.6', _resolve_bump(current: '2.0.6', bump_type: '4.5.6'), "an explicit semver is used as-is")

# MARKETING_VERSION is "1.0" on the test targets, so short versions are real.
assert_equal('1.0.1', _resolve_bump(current: '1.0', bump_type: 'patch'), "a two-component version is padded")
assert_equal('1.1.0', _resolve_bump(current: '1.0', bump_type: 'minor'), "a two-component version bumps minor")

assert_equal('2.0.10', _resolve_bump(current: '2.0.9', bump_type: 'patch'), "patch crosses into double digits")

# A typo must not silently downgrade the version and tag a release for it.
assert_raises("an unknown bump type is rejected")   { _resolve_bump(current: '2.0.6', bump_type: 'pathc') }
assert_raises("a non-semver string is rejected")    { _resolve_bump(current: '2.0.6', bump_type: '2.0') }
assert_raises("an empty bump type is rejected")     { _resolve_bump(current: '2.0.6', bump_type: '') }

puts
puts "_parse_unreleased_subsections"

# The template [Unreleased] block ships empty subsections, so this shape is the
# normal one rather than an edge case.
with_empty = <<~MD
  ## [Unreleased]

  ### Added

  ### Changed
  - A changed thing

  ### Fixed
  - A fixed thing

  ## [1.0] - 2020-01-01

  ### Added
  - Old thing
MD

parsed = _parse_unreleased_subsections(with_empty)
assert_equal(['Changed', 'Fixed'], parsed.keys.sort, "empty subsections are omitted, not populated")
assert_equal(['A changed thing'], parsed['Changed'], "items stay under their own heading")
assert_equal(['A fixed thing'], parsed['Fixed'], "the last subsection is parsed")
assert_equal(false, parsed.key?('Added'), "an empty subsection does not absorb the next one")

populated = <<~MD
  ## [Unreleased]

  ### Added
  - An added thing

  ### Changed
  - A changed thing

  ## [1.0] - 2020-01-01
MD
assert_equal(['Added', 'Changed'], _parse_unreleased_subsections(populated).keys.sort, "fully populated sections parse")

# Non-standard headings are preserved -- that is what stops a hand-written
# "Security" section from being dropped at release time.
custom = "## [Unreleased]\n\n### Security\n- Patched a thing\n\n## [1.0] - 2020-01-01\n"
assert_equal(['Patched a thing'], _parse_unreleased_subsections(custom)['Security'], "custom headings survive")

assert_equal({}, _parse_unreleased_subsections("# Changelog\n\n## [1.0] - 2020-01-01\n"), "no [Unreleased] yields nothing")
assert_equal({}, _parse_unreleased_subsections("## [Unreleased]\n\n### Added\n\n### Fixed\n\n## [1.0] - 2020-01-01\n"), "an entirely empty block yields nothing")

# The block must not run past its own section into the released history.
bleed = "## [Unreleased]\n\n### Added\n- Pending\n\n## [1.0] - 2020-01-01\n\n### Added\n- Shipped\n"
assert_equal(['Pending'], _parse_unreleased_subsections(bleed)['Added'], "parsing stops at the next version heading")

puts
puts "TestFlight notes"

notes = format_testflight_notes({ 'Added' => ['One', 'Two'], 'Fixed' => ['Three'] })
assert_equal("Added\n• One\n• Two\n\nFixed\n• Three", notes, "sections render as headed bullet lists")
assert_equal(nil, format_testflight_notes({}), "no sections yields nil, not an empty string")
assert_equal(nil, format_testflight_notes(nil), "nil sections yields nil")
assert_equal(nil, format_testflight_notes({ 'Added' => [] }), "a section with no items yields nil")
assert_equal("Fixed\n• Real", format_testflight_notes({ 'Added' => [], 'Fixed' => ['Real'] }), "empty sections are skipped, populated ones kept")

commits = [
  'feat(grid): Add a hint button (#12)',
  'chore: Bump a dependency',
  'fix: Stop the crash on rotate',
  'ci(codeql): Speed up analysis',
  'docs: Explain something'
]
assert_equal("• Add a hint button\n• Stop the crash on rotate", format_commit_notes(commits),
             "only tester-relevant types survive, prefixes and PR numbers stripped")
assert_equal(nil, format_commit_notes(['chore: Tooling', 'ci: More tooling']), "a tooling-only run yields nil")
assert_equal(nil, format_commit_notes([]), "no commits yields nil")
assert_equal(nil, format_commit_notes(nil), "nil commits yields nil")
assert_equal("• Something", format_commit_notes(['feat!: Something']), "a breaking-change marker is handled")
assert_equal("• Keep (#12) inside", format_commit_notes(['fix: Keep (#12) inside']), "only a trailing PR number is stripped")
assert_equal(nil, format_commit_notes(['Not conventional at all']), "an unparseable subject is skipped")

short = "Added\n• A thing"
assert_equal(short, truncate_testflight_notes(short), "text under the limit is untouched")
assert_equal(nil, truncate_testflight_notes(nil), "nil passes through")

long = 'x' * (TESTFLIGHT_NOTES_LIMIT + 500)
truncated = truncate_testflight_notes(long)
assert_equal(true, truncated.length <= TESTFLIGHT_NOTES_LIMIT, "output never exceeds the limit")
assert_equal(true, truncated.end_with?('(truncated)'), "truncation is announced")

exact = 'x' * TESTFLIGHT_NOTES_LIMIT
assert_equal(exact, truncate_testflight_notes(exact), "text exactly at the limit is untouched")
assert_equal(true, truncate_testflight_notes('x' * 20, limit: 5).length <= 5, "a limit shorter than the marker still fits")

puts
puts "commit_subjects_since_last_tag"

# Exercised against real repositories: this is where the range is built, and
# the previous version substituted a sentinel revision for the no-tag case.
Dir.mktmpdir do |dir|
  run = lambda do |*args|
    _out, _err, status = Open3.capture3('git', '-C', dir, *args)
    raise "git #{args.join(' ')} failed" unless status.success?
  end

  run.call('init', '-q', '.')
  run.call('config', 'user.email', 'test@example.com')
  run.call('config', 'user.name', 'Test')
  run.call('commit', '-q', '--allow-empty', '-m', 'feat: Before the tag')

  Dir.chdir(dir) do
    assert_equal(['feat: Before the tag'], commit_subjects_since_last_tag,
                 "with no tags, every commit is returned")
  end

  run.call('tag', 'v1.0.0')
  run.call('commit', '-q', '--allow-empty', '-m', 'fix: After the tag')
  run.call('commit', '-q', '--allow-empty', '-m', 'chore: Also after')

  Dir.chdir(dir) do
    subjects = commit_subjects_since_last_tag
    assert_equal(['fix: After the tag', 'chore: Also after'].sort, subjects.sort,
                 "with a tag, only commits after it are returned")
    assert_equal(false, subjects.include?('feat: Before the tag'),
                 "the tagged commit itself is excluded")
    assert_equal("• After the tag", format_commit_notes(subjects),
                 "the range feeds through to tester-facing notes")
  end
end

# Outside a repository entirely, git fails and the helper stays quiet.
Dir.mktmpdir do |dir|
  Dir.chdir(dir) do
    assert_equal([], commit_subjects_since_last_tag, "outside a git repository, no subjects and no raise")
  end
end

puts
puts "_resolve_target_version"

# MARKETING_VERSION states the version under development, so with no bump a
# release ships exactly what the project already says. Bumping at release time
# was what left the project on the just-shipped version and made beta unusable
# until the next deploy (#95).
assert_equal('2.0.7', _resolve_target_version(current: '2.0.7', bump_type: nil), "no bump ships the current version")
assert_equal('2.0.7', _resolve_target_version(current: '2.0.7', bump_type: ''), "an empty bump ships the current version")
assert_equal('2.0.7', _resolve_target_version(current: '2.0.7', bump_type: '   '), "a whitespace bump ships the current version")

assert_equal('2.1.0', _resolve_target_version(current: '2.0.7', bump_type: 'minor'), "minor changes train")
assert_equal('3.0.0', _resolve_target_version(current: '2.0.7', bump_type: 'major'), "major changes train")
assert_equal('2.0.8', _resolve_target_version(current: '2.0.7', bump_type: 'patch'), "patch still works if asked for")
assert_equal('4.5.6', _resolve_target_version(current: '2.0.7', bump_type: '4.5.6'), "an explicit version is honored")

# A typo must not silently ship something unintended.
assert_raises("an unknown bump type is still rejected") { _resolve_target_version(current: '2.0.7', bump_type: 'pathc') }

puts
puts "age rating config"

# The answers Apple requires from September 2026. They live in the repository
# so a submission cannot go out with stale ones, and so a change to them is
# reviewable rather than a silent edit in the App Store Connect UI.
rating_path = File.expand_path('../metadata/app_rating_config.json', __dir__)
assert_equal(true, File.exist?(rating_path), "the age rating config is committed")

rating = JSON.parse(File.read(rating_path)) rescue nil
assert_equal(true, !rating.nil?, "it is valid JSON")

if rating
  %w[socialMedia socialMediaAgeRestricted messagingAndChat userGeneratedContent
     unrestrictedWebAccess ageAssurance parentalControls].each do |key|
    assert_equal(true, rating.key?(key), "answers the '#{key}' question")
  end

  # gamblingAndContests was split into gambling + contests; leaving it in makes
  # deliver emit a deprecation on every upload.
  assert_equal(false, rating.key?('gamblingAndContests'), "omits the deprecated gamblingAndContests")
  assert_equal(true, rating.key?('gambling') && rating.key?('contests'), "uses the split keys instead")

  # A null is not an answer, and Apple treats the section as incomplete.
  assert_equal([], rating.select { |_, v| v.nil? }.keys, "contains no null answers")
end

puts
puts "_preflight row classification"

rows = []
_preflight(rows, 'good') { 'a value' }
assert_equal([['good', :ok, 'a value']], rows, "a value is recorded as ok")

rows = []
_preflight(rows, 'boom') { raise 'something broke' }
assert_equal(:fail, rows[0][1], "a raise is recorded as a failure")
assert_equal('something broke', rows[0][2], "the message is kept")

# A check that raises must not abort the run: three problems should be
# reported together, not discovered one release attempt at a time.
rows = []
_preflight(rows, 'one') { raise 'first' }
_preflight(rows, 'two') { raise 'second' }
_preflight(rows, 'three') { 'fine' }
assert_equal(3, rows.length, "a failing check does not stop later ones")
assert_equal([:fail, :fail, :ok], rows.map { |r| r[1] }, "each is classified independently")

# Only the first line of a multi-line error, so one failure cannot flood the table.
rows = []
_preflight(rows, 'multi') { raise "headline\nstack frame\nmore detail" }
assert_equal('headline', rows[0][2], "only the first line of an error is shown")

rows = []
_preflight(rows, 'nothing') { nil }
assert_equal(:fail, rows[0][1], "nil is a failure by default")
assert_equal('not available', rows[0][2], "and says so")

rows = []
_preflight(rows, 'empty') { '' }
assert_equal(:fail, rows[0][1], "an empty string is a failure, not a pass")

# gh is optional because publish_github_release soft-fails; its absence must
# warn rather than read as a blocked release.
rows = []
_preflight(rows, 'optional', severity: :warn) { nil }
assert_equal(:warn, rows[0][1], "a missing optional check warns instead of failing")

rows = []
_preflight(rows, 'optional', severity: :warn) { raise 'gone' }
assert_equal(:warn, rows[0][1], "an optional check that raises also only warns")

puts
puts "executable_in_path?"

Dir.mktmpdir do |dir|
  original_path = ENV['PATH']
  begin
    tool = File.join(dir, 'faketool')
    File.write(tool, "#!/bin/sh\nexit 0\n")

    ENV['PATH'] = dir
    File.chmod(0o644, tool)
    assert_equal(false, executable_in_path?('faketool'), "a non-executable file is not found")

    File.chmod(0o755, tool)
    assert_equal(true, executable_in_path?('faketool'), "an executable on PATH is found")
    assert_equal(false, executable_in_path?('nope'), "an absent name is not found")

    # A directory sharing the name must not count as the executable.
    subdir = File.join(dir, 'adir')
    FileUtils.mkdir_p(subdir)
    assert_equal(false, executable_in_path?('adir'), "a directory is not mistaken for an executable")

    # Empty PATH entries mean "current directory" to some tools; skip them
    # rather than resolving relative to wherever the lane happens to run.
    ENV['PATH'] = "::#{dir}"
    assert_equal(true, executable_in_path?('faketool'), "empty PATH entries are skipped")

    ENV['PATH'] = ''
    assert_equal(false, executable_in_path?('faketool'), "an empty PATH finds nothing")
  ensure
    ENV['PATH'] = original_path
  end
end

# The real thing, as a sanity check that the scan agrees with reality.
assert_equal(true, executable_in_path?('ruby'), "ruby is found on the real PATH")

puts
puts "shipped_store_locales"

REPO_ROOT = File.expand_path('../..', __dir__)

# The manifest is the single declaration of what ships (conventions/
# shared-rule-single-source.md); this reads it through the same script that
# CI checks the other registries with, rather than parsing it a second time.
locales = shipped_store_locales(root: REPO_ROOT)
assert_equal(true, locales.include?('en-US'), "the English listing is declared")
assert_equal(true, locales.include?('es-MX'), "the Spanish listing is declared")
assert_equal(locales, locales.uniq, "no locale is listed twice")

puts
puts "generate_release_notes writes every shipped locale"

# The whole point: a release used to update en-US only, so the moment a second
# listing existed its notes would freeze at whatever shipped that day while
# every later release quietly passed it by.
Dir.mktmpdir do |root|
  %w[en-US es-MX].each { |l| FileUtils.mkdir_p(File.join(root, 'fastlane', 'metadata', l)) }
  File.write(File.join(root, 'CHANGELOG.md'), CHANGELOG)

  prose = generate_release_notes(version: '2.0.6', root: root, locales: %w[en-US es-MX])

  english = File.read(File.join(root, 'fastlane', 'metadata', 'en-US', 'release_notes.txt'))
  spanish = File.read(File.join(root, 'fastlane', 'metadata', 'es-MX', 'release_notes.txt'))

  assert_equal(true, english.downcase.include?('undo and hint assists'), "the notes come from the changelog section")
  assert_equal(english, spanish, "every shipped locale gets the notes")
  assert_equal(prose, english, "the returned prose is what was written")
end

# A locale declared but not yet created would otherwise crash mid-release with
# Errno::ENOENT, after the archive and partway through deliver.
Dir.mktmpdir do |root|
  FileUtils.mkdir_p(File.join(root, 'fastlane', 'metadata', 'en-US'))
  File.write(File.join(root, 'CHANGELOG.md'), CHANGELOG)

  assert_raises("a declared locale with no metadata directory is a clear error") do
    generate_release_notes(version: '2.0.6', root: root, locales: %w[en-US es-MX])
  end
end

puts
puts "release notes are written in each locale's own language"

# Every locale getting the same English prose was the known limitation of the
# fan-out: correct on the day the listings were created and English forever
# after. The generator is now asked once per locale, and told which one.
Dir.mktmpdir do |root|
  %w[en-US de-DE ja].each { |l| FileUtils.mkdir_p(File.join(root, 'fastlane', 'metadata', l)) }
  File.write(File.join(root, 'CHANGELOG.md'), CHANGELOG)
  AIHelper.reset!(available: true, prose: ->(locale) { "notes for #{locale}" })

  generate_release_notes(version: '2.0.6', root: root, locales: %w[en-US de-DE ja])

  assert_equal(%w[en-US de-DE ja], AIHelper.locales_asked, "each locale is asked for separately")
  %w[en-US de-DE ja].each do |locale|
    written = File.read(File.join(root, 'fastlane', 'metadata', locale, 'release_notes.txt'))
    assert_equal("notes for #{locale}", written, "#{locale} gets its own prose")
  end
end

# Without a key the template path runs, and the template is English. Writing
# English into every listing is the deliberate answer rather than an accident:
# notes in the wrong language still describe the right version, where stale
# notes describe a release the user does not have.
Dir.mktmpdir do |root|
  %w[en-US de-DE].each { |l| FileUtils.mkdir_p(File.join(root, 'fastlane', 'metadata', l)) }
  File.write(File.join(root, 'CHANGELOG.md'), CHANGELOG)
  AIHelper.reset!(available: false)

  generate_release_notes(version: '2.0.6', root: root, locales: %w[en-US de-DE])

  english = File.read(File.join(root, 'fastlane', 'metadata', 'en-US', 'release_notes.txt'))
  german  = File.read(File.join(root, 'fastlane', 'metadata', 'de-DE', 'release_notes.txt'))
  assert_equal([], AIHelper.locales_asked, "no generation is attempted without a key")
  assert_equal(english, german, "every locale gets the template when there is no key")
  assert_equal(true, english.downcase.include?('undo and hint assists'), "the template still comes from the changelog")
end

# One locale failing must not ship a mix of languages, and must not leave a
# listing on notes for an older version. Consistency over partial success:
# everything falls back together.
Dir.mktmpdir do |root|
  %w[en-US de-DE ja].each { |l| FileUtils.mkdir_p(File.join(root, 'fastlane', 'metadata', l)) }
  File.write(File.join(root, 'CHANGELOG.md'), CHANGELOG)
  AIHelper.reset!(available: true, prose: ->(locale) { locale == 'de-DE' ? nil : "notes for #{locale}" })

  generate_release_notes(version: '2.0.6', root: root, locales: %w[en-US de-DE ja])

  written = %w[en-US de-DE ja].map { |l| File.read(File.join(root, 'fastlane', 'metadata', l, 'release_notes.txt')) }
  assert_equal(1, written.uniq.length, "a failure for one locale falls back for all of them")
  assert_equal(false, written.first.include?('notes for'), "no locale keeps its AI prose when another failed")
  assert_equal(true, written.first.downcase.include?('undo and hint assists'), "the fallback is the template")
end

# Over-long notes are cut to fit the App Store limit, and the sentence that
# marks the cut is English. Adding it to a Japanese listing would put an
# English sentence on the end of Japanese prose -- the same mixing the
# generator was just taught to avoid.
Dir.mktmpdir do |root|
  %w[en-US ja].each { |l| FileUtils.mkdir_p(File.join(root, 'fastlane', 'metadata', l)) }
  File.write(File.join(root, 'CHANGELOG.md'), CHANGELOG)
  AIHelper.reset!(available: true, prose: ->(locale) { "#{locale} " + ('x' * 4100) })

  generate_release_notes(version: '2.0.6', root: root, locales: %w[en-US ja])

  english = File.read(File.join(root, 'fastlane', 'metadata', 'en-US', 'release_notes.txt'))
  japanese = File.read(File.join(root, 'fastlane', 'metadata', 'ja', 'release_notes.txt'))

  assert_equal(true, english.length <= 4000, "English is cut to the limit")
  assert_equal(true, japanese.length <= 4000, "Japanese is cut to the limit")
  assert_equal(true, english.include?('Thank you for playing'), "English says why it stops")
  assert_equal(false, japanese.include?('Thank you for playing'), "Japanese is not given an English closing")
end

# A missing changelog is reported, not raised: the release can still proceed
# with whatever notes are already in place.
Dir.mktmpdir do |root|
  FileUtils.mkdir_p(File.join(root, 'fastlane', 'metadata', 'en-US'))
  assert_equal(nil, generate_release_notes(version: '2.0.6', root: root, locales: %w[en-US]),
               "a missing changelog returns nil rather than raising")
end

# The release slot: whether App Store Connect's edit version can take a release.
#
# preflight reported "2.0.7 (29) ready to submit" while 2.0.7 was sitting in
# WAITING_FOR_REVIEW (#148). App Store Connect keeps calling a version the
# "edit" version right through review, so reading the version string without
# its state cannot tell "waiting for you" from "waiting for Apple" -- and the
# second one means a release written into that slot is rejected (#149).
puts
puts "_app_store_slot_status"

assert_equal(:none, _app_store_slot_status(nil), "no edit version means no occupied slot")
assert_equal(:none, _app_store_slot_status(''), "an empty state means no occupied slot")

assert_equal(:editable, _app_store_slot_status('PREPARE_FOR_SUBMISSION'), "PREPARE_FOR_SUBMISSION is editable")
assert_equal(:editable, _app_store_slot_status('DEVELOPER_REJECTED'), "a version pulled from review is editable again")
assert_equal(:editable, _app_store_slot_status('REJECTED'), "a rejected version is back in the developer's hands")
assert_equal(:editable, _app_store_slot_status('METADATA_REJECTED'), "a metadata rejection is editable")
assert_equal(:editable, _app_store_slot_status('INVALID_BINARY'), "an invalid binary is editable")

assert_equal(:locked, _app_store_slot_status('WAITING_FOR_REVIEW'), "WAITING_FOR_REVIEW is locked -- the state that produced #148")
assert_equal(:locked, _app_store_slot_status('IN_REVIEW'), "IN_REVIEW is locked")
assert_equal(:locked, _app_store_slot_status('PENDING_DEVELOPER_RELEASE'), "an approved version still holds the slot")
assert_equal(:locked, _app_store_slot_status('PENDING_APPLE_RELEASE'), "a version awaiting Apple's release holds the slot")
assert_equal(:locked, _app_store_slot_status('PROCESSING_FOR_APP_STORE'), "a processing version holds the slot")

# Default-deny. Apple has added states before, and the two failures are not
# symmetric: a wrong "locked" costs a human one look at the named state, while
# a wrong "editable" costs a release that dies at upload_to_app_store with the
# changelog already committed and a build number already spent.
assert_equal(:locked, _app_store_slot_status('SOME_STATE_APPLE_ADDS_LATER'),
             "an unrecognized state is treated as locked, not assumed safe")

puts
puts "_release_slot_row"

status, message = _release_slot_row(version: nil, state: nil)
assert_equal(:ok, status, "an empty slot passes")
assert_equal(true, message.include?('free'), "and says the slot is free")

status, message = _release_slot_row(version: '2.1.0', state: 'PREPARE_FOR_SUBMISSION')
assert_equal(:ok, status, "an editable slot passes")
assert_equal(true, message.include?('2.1.0'), "and names the version occupying it")

status, message = _release_slot_row(version: '2.0.7', state: 'WAITING_FOR_REVIEW')
assert_equal(:fail, status, "a locked slot fails rather than warns")
assert_equal(true, message.include?('2.0.7'), "and names the version holding the slot")
assert_equal(true, message.include?('WAITING_FOR_REVIEW'), "and names the state, so the wait is understood")
# The two remedies have very different costs -- waiting keeps the queued
# version's place, removing it forfeits that -- so the row has to say both
# rather than leave the reader to guess which one it means.
assert_equal(true, message.downcase.include?('remove'), "and names removing it from review as the other remedy")

puts
puts "_describe_pending_submission"

# The row preflight actually prints. It said "ready to submit" for a version
# already queued, which is the sentence that misled the release decision.
assert_equal(nil, _describe_pending_submission(version: nil, state: nil, build: nil),
             "nothing pending reports nothing")

message = _describe_pending_submission(version: '2.0.7', state: 'PREPARE_FOR_SUBMISSION', build: 29)
assert_equal(true, message.include?('ready to submit'), "a genuinely pending version is ready to submit")
assert_equal(true, message.include?('29'), "and names its build")

message = _describe_pending_submission(version: '2.0.7', state: 'PREPARE_FOR_SUBMISSION', build: nil)
assert_equal(true, message.include?('no processed build'), "a pending version with no build says so")

message = _describe_pending_submission(version: '2.0.7', state: 'WAITING_FOR_REVIEW', build: 29)
assert_equal(false, message.include?('ready to submit'), "a version in review is never 'ready to submit'")
assert_equal(true, message.include?('WAITING_FOR_REVIEW'), "it reports the state it is actually in")
# conventions/changelog.md: the entries a pull request authors ARE the release
# section. Deriving a second set from commit subjects and appending it to them
# described the same work twice -- uniq! compares exact strings, so "Play in
# seven languages" and "Add French, Dutch and Korean localizations" both
# survived -- and swept in CI and test commits no player can observe.
puts
puts "_unreleased_entry_count"

EMPTY_UNRELEASED = <<~MD
  # Changelog

  ## [Unreleased]

  ### Added

  ### Changed

  ### Fixed

  ## [2.0.7] - 2026-09-06

  ### Fixed
  - Something released
MD

AUTHORED_UNRELEASED = <<~MD
  # Changelog

  ## [Unreleased]

  ### Added
  - Play in seven languages
  - Something else

  ### Changed

  ### Fixed
  - Stop the board crashing in Spanish

  ## [2.0.7] - 2026-09-06

  ### Fixed
  - Something released
MD

# The exact state 26 commits accumulated against: headers present, nothing
# under them. extract_changelog_section calls this section non-empty, which is
# why preflight reported "5 line(s) under [Unreleased]" for it and passed.
assert_equal(0, _unreleased_entry_count(EMPTY_UNRELEASED), "empty subsection headers are not entries")
assert_equal(3, _unreleased_entry_count(AUTHORED_UNRELEASED), "authored bullets are counted across subsections")
assert_equal(0, _unreleased_entry_count("# Changelog\n\n## [1.0] - 2020-01-01\n"), "no [Unreleased] block is zero entries")
# Counting the whole file rather than the block would pick these up.
assert_equal(false, _unreleased_entry_count(EMPTY_UNRELEASED) > 0, "released sections below are not counted")

puts
puts "_derive_from_commits?"

assert_equal(true, _derive_from_commits?(_parse_unreleased_subsections(EMPTY_UNRELEASED)),
             "an unauthored section still falls back to commit subjects")
assert_equal(false, _derive_from_commits?(_parse_unreleased_subsections(AUTHORED_UNRELEASED)),
             "an authored section is the release; nothing is derived on top of it")
assert_equal(true, _derive_from_commits?({}), "no authored sections means derive")
assert_equal(true, _derive_from_commits?(nil), "a missing section is not a crash")

puts
puts "app_store_edit_version"

Spaceship::ConnectAPI::App.reset_stubs!
assert_equal(nil, app_store_edit_version, "an app with no version in progress reports nil")

Spaceship::ConnectAPI::App.stub_edit = Spaceship::ConnectAPI::StubEditVersion.new('2.0.7', 'WAITING_FOR_REVIEW')
info = app_store_edit_version
assert_equal('2.0.7', info[:version], "the occupying version is reported")
assert_equal('WAITING_FOR_REVIEW', info[:state], "with the state App Store Connect gave")
assert_equal(:locked, info[:status], "and the status derived from it")

# get_edit_app_store_version filters on a fixed state list that stops at
# WAITING_FOR_REVIEW. The moment Apple starts reviewing, it returns nil -- and
# nil is a PASS. Watched live: 2.0.7 moved WAITING_FOR_REVIEW -> IN_REVIEW and
# the row flipped from correctly failing to "free — no version in progress"
# while Apple was actively reviewing it.
Spaceship::ConnectAPI::App.reset_stubs!
Spaceship::ConnectAPI::App.stub_in_review = Spaceship::ConnectAPI::StubEditVersion.new('2.0.7', 'IN_REVIEW')
info = app_store_edit_version
assert_equal('2.0.7', info[:version], "a version in review still holds the slot")
assert_equal(:locked, info[:status], "and is reported as locked, not absent")

# Same gap one state further on: an approved version awaiting release is
# invisible to the edit accessor and still occupies the slot.
Spaceship::ConnectAPI::App.reset_stubs!
Spaceship::ConnectAPI::App.stub_pending_release = Spaceship::ConnectAPI::StubEditVersion.new('2.0.7', 'PENDING_DEVELOPER_RELEASE')
info = app_store_edit_version
assert_equal('2.0.7', info[:version], "a version awaiting release still holds the slot")
assert_equal(:locked, info[:status], "and is reported as locked")

Spaceship::ConnectAPI::App.reset_stubs!
Spaceship::ConnectAPI::App.stub_edit = Spaceship::ConnectAPI::StubEditVersion.new('2.1.0', 'PREPARE_FOR_SUBMISSION')
assert_equal(:editable, app_store_edit_version[:status], "a version waiting on the developer is editable")

# The failure mode that matters. Rescuing to nil makes an unreachable App Store
# Connect indistinguishable from an empty slot -- and an empty slot is a PASS,
# so a network blip would have reported "Release slot: free" and waved through
# the release this row exists to stop. Raising lets _preflight record the row as
# failed and lets the submit lane report the real reason.
Spaceship::ConnectAPI::App.reset_stubs!
Spaceship::ConnectAPI::App.stub_error = StandardError.new('connection reset by peer')

raised = begin
  app_store_edit_version
  false
rescue StandardError
  true
end
assert_equal(true, raised, "an unreadable App Store Connect raises rather than reporting an empty slot")

message = begin
  app_store_edit_version
  ''
rescue StandardError => e
  e.message
end
assert_equal(true, message.include?('connection reset by peer'), "and carries the underlying reason")
assert_equal(true, message.include?('App Store Connect'), "and says what could not be read")

Spaceship::ConnectAPI::App.reset_stubs!

puts
puts "generated release notes are checked before they are uploaded"

# Both defects that reached ten App Store listings in 2.1.0 were found by a
# person reading the files after the upload (#166). These are the properties of
# a listing that hold or do not hold without anyone judging the prose.

TRANSLATION_CONVENTION = <<~MD
  # Translation

  ## Register is declared once per language

  | Language | Register | Note |
  | --- | --- | --- |
  | Spanish (`es`) | `tú`, neutral Latin American | no *vosotros* |
  | German (`de`) | `du` | what German games use |
  | French (`fr`) | `tu` | casual game register |
  | Japanese (`ja`) | です/ます, bare nouns for labels | polite sentences |
MD

GOOD_NOTES = {
  'en-US' => "Leaves of Blocks speaks your language.\n\n• Ten languages\n\nThank you for playing Leaves of Blocks!",
  'de-DE' => "Leaves of Blocks spricht deine Sprache.\n\n• Zehn Sprachen\n\nDanke, dass du spielst!",
  'fr-FR' => "Leaves of Blocks parle ta langue.\n\n• Dix langues\n\nMerci de jouer !",
  'ja'    => "Leaves of Blocks が日本語に対応しました。\n\n• 10言語\n\n遊んでいただきありがとうございます。"
}.freeze

PAIRS = [%w[en-US en], %w[de-DE de], %w[fr-FR fr], %w[ja ja]].freeze

def notes_fixture(root, overrides = {})
  FileUtils.mkdir_p(File.join(root, 'conventions'))
  File.write(File.join(root, 'conventions', 'translation.md'), TRANSLATION_CONVENTION)
  GOOD_NOTES.merge(overrides).each do |locale, text|
    dir = File.join(root, 'fastlane', 'metadata', locale)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, 'release_notes.txt'), text) unless text.nil?
  end
end

Dir.mktmpdir do |root|
  notes_fixture(root)
  ok_result = begin
    verify_release_notes(root: root, pairs: PAIRS)
    true
  rescue StandardError => e
    "raised #{e.message}"
  end
  assert_equal(true, ok_result, "a correct set of notes passes")
end

# The English template written to every listing is what 2.1.0 uploaded, and
# identical files are its signature: ten locales cannot legitimately hold the
# same bytes.
Dir.mktmpdir do |root|
  notes_fixture(root, 'de-DE' => GOOD_NOTES['en-US'])
  assert_raises("identical notes in two locales are the template fallback") do
    verify_release_notes(root: root, pairs: PAIRS)
  end
end

# conventions/translation.md declares du for German. Copilot caught this by
# reading; it is a grep.
Dir.mktmpdir do |root|
  notes_fixture(root, 'de-DE' => "Leaves of Blocks spricht jetzt Ihre Sprache.\n\nDanke!")
  assert_raises("formal register against a convention declaring du") do
    verify_release_notes(root: root, pairs: PAIRS)
  end
end

Dir.mktmpdir do |root|
  notes_fixture(root, 'fr-FR' => "Leaves of Blocks parle votre langue.\n\nMerci !")
  assert_raises("formal register against a convention declaring tu") do
    verify_release_notes(root: root, pairs: PAIRS)
  end
end

# "Never translate: Leaves of Blocks" is already in the convention. zh-Hans
# coined 《叶块消消乐》 for it, which is not a name the app is published under.
Dir.mktmpdir do |root|
  notes_fixture(root, 'ja' => "《叶块消消乐》が日本語に対応しました。\n\nありがとうございます。")
  assert_raises("a listing that never names the product is a translated name") do
    verify_release_notes(root: root, pairs: PAIRS)
  end
end

# Four listings described the escape-sequence fix by printing the escape.
Dir.mktmpdir do |root|
  notes_fixture(root, 'fr-FR' => "Leaves of Blocks : l'étiquette affichait « \\n ».\n\nMerci !")
  assert_raises("a literal escape sequence in store copy") do
    verify_release_notes(root: root, pairs: PAIRS)
  end
end

# Two closings stacked, which is what the too-literal safety net produced.
Dir.mktmpdir do |root|
  notes_fixture(root,
                'en-US' => "Leaves of Blocks news.\n\nThanks so much for playing Leaves of Blocks!\n\nThank you for playing Leaves of Blocks!")
  assert_raises("an English listing closing twice") do
    verify_release_notes(root: root, pairs: PAIRS)
  end
end

Dir.mktmpdir do |root|
  notes_fixture(root, 'de-DE' => "Leaves of Blocks. #{'x' * 4100}")
  assert_raises("notes past the App Store character limit") do
    verify_release_notes(root: root, pairs: PAIRS)
  end
end

Dir.mktmpdir do |root|
  notes_fixture(root, 'de-DE' => '   ')
  assert_raises("an empty listing") do
    verify_release_notes(root: root, pairs: PAIRS)
  end
end

Dir.mktmpdir do |root|
  notes_fixture(root, 'de-DE' => nil)
  assert_raises("a declared locale with no notes file") do
    verify_release_notes(root: root, pairs: PAIRS)
  end
end

# Japanese declares です/ます, not a pronoun, so the formal-marker patterns do
# not apply to it -- and a language the convention says nothing about is not
# guessed at.
Dir.mktmpdir do |root|
  notes_fixture(root, 'ja' => "Leaves of Blocks が10言語に対応しました。\n\nありがとうございます。")
  passed = begin
    verify_release_notes(root: root, pairs: PAIRS)
    true
  rescue StandardError => e
    "raised #{e.message}"
  end
  assert_equal(true, passed, "a language with no pronoun register declared is left alone")
end

puts
if $fail.zero?
  puts "All #{$pass} checks passed."
  exit 0
end
puts "#{$fail} failed, #{$pass} passed."
exit 1
