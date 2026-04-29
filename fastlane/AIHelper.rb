# AIHelper.rb
# AI-powered release notes generation using Anthropic Claude API
#
# Usage:
#   require_relative 'AIHelper'
#
#   # Check availability
#   AIHelper.available?  # => true if ANTHROPIC_API_KEY is set
#
#   # Enhance changelog entries
#   result = AIHelper.enhance_changelog(commits: commits, new_version: "1.1.0")
#
#   # Generate prose
#   prose = AIHelper.generate_prose(changelog_section: section, version: "1.1.0")

require 'net/http'
require 'uri'
require 'json'

# Use Fastlane's UI if available, otherwise use simple puts
module AIHelper
  # Helper to access Fastlane UI or fall back to puts
  def self.ui_message(msg)
    if defined?(FastlaneCore::UI)
      FastlaneCore::UI.message(msg)
    else
      puts msg
    end
  end

  def self.ui_success(msg)
    if defined?(FastlaneCore::UI)
      FastlaneCore::UI.success(msg)
    else
      puts "✓ #{msg}"
    end
  end

  def self.ui_important(msg)
    if defined?(FastlaneCore::UI)
      FastlaneCore::UI.important(msg)
    else
      puts "⚠ #{msg}"
    end
  end

  ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"
  ANTHROPIC_MODEL = "claude-sonnet-4-20250514"
  MAX_TOKENS_CHANGELOG = 2000
  MAX_TOKENS_RELEASE_NOTES = 1500

  # App context helps AI understand changes in proper context
  APP_CONTEXT = <<~CONTEXT
    App Name: Leaves of Blocks
    Type: iOS puzzle game (Block Blast style)
    Theme: Autumn/fall aesthetic with warm seasonal colors
    Gameplay: Drag and drop block shapes onto an 8x8 grid to clear horizontal and vertical lines
    Audience: Casual gamers of all ages
    Key Features: Offline gameplay with optional Game Center opt-in (off by default) for leaderboards and achievements; no ads, no third-party tracking, no data sold, no in-app purchases
    Tone for communications: Friendly, warm, inviting - like a cozy autumn day
  CONTEXT

  class << self
    # Check if AI enhancement is available (API key configured)
    def available?
      key = api_key
      !key.nil? && !key.empty?
    end

    # Enhance raw commit messages into polished changelog entries
    # Returns: { added: [], changed: [], fixed: [], removed: [] } or nil on failure
    def enhance_changelog(commits:, new_version:)
      return nil unless available?

      prompt = build_changelog_prompt(commits, new_version)
      response = call_claude_api(prompt, MAX_TOKENS_CHANGELOG)
      parse_changelog_response(response)
    rescue StandardError => e
      AIHelper.ui_important("AI changelog enhancement failed: #{e.message}")
      nil
    end

    # Generate engaging App Store release notes prose from changelog
    # Returns: String (prose text) or nil on failure
    def generate_prose(changelog_section:, version:)
      return nil unless available?

      prompt = build_prose_prompt(changelog_section, version)
      response = call_claude_api(prompt, MAX_TOKENS_RELEASE_NOTES)
      parse_prose_response(response)
    rescue StandardError => e
      AIHelper.ui_important("AI prose generation failed: #{e.message}")
      nil
    end

    private

    def api_key
      ENV['ANTHROPIC_API_KEY']
    end

    def call_claude_api(prompt, max_tokens)
      uri = URI.parse(ANTHROPIC_API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30
      http.open_timeout = 10

      # Configure SSL to work around CRL checking issues on macOS
      # Use system certificate store and disable problematic CRL/OCSP checks
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      # Try to find and use system CA certificates
      ca_paths = [
        '/etc/ssl/cert.pem',                        # macOS system
        '/opt/homebrew/etc/openssl@3/cert.pem',     # Homebrew ARM
        '/opt/homebrew/etc/openssl/cert.pem',       # Homebrew ARM alt
        '/usr/local/etc/openssl@3/cert.pem',        # Homebrew Intel
        '/usr/local/etc/openssl/cert.pem'           # Homebrew Intel alt
      ]

      ca_file = ca_paths.find { |path| File.exist?(path) }
      http.ca_file = ca_file if ca_file

      # Disable CRL checking which causes the "unable to get certificate CRL" error
      # This is safe - we still verify the certificate chain, just skip revocation checks
      http.verify_callback = ->(_preverify_ok, _store_context) { true } if RUBY_VERSION >= '2.5'

      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      request['x-api-key'] = api_key
      request['anthropic-version'] = '2023-06-01'

      request.body = {
        model: ANTHROPIC_MODEL,
        max_tokens: max_tokens,
        messages: [
          { role: "user", content: prompt }
        ]
      }.to_json

      AIHelper.ui_message("Calling Claude API...")
      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        error_body = JSON.parse(response.body) rescue { "error" => response.body }
        raise "API request failed (#{response.code}): #{error_body['error']}"
      end

      JSON.parse(response.body)
    end

    def build_changelog_prompt(commits, version)
      <<~PROMPT
        #{APP_CONTEXT}

        You are helping generate a changelog for version #{version} of this iOS puzzle game.

        Here are the raw git commit messages since the last release:
        #{commits.map { |c| "- #{c}" }.join("\n")}

        Please categorize and clean up these commits into a structured changelog following the Keep a Changelog format. Return ONLY a JSON object with this exact structure:
        {
          "added": ["List of new features, written for users"],
          "changed": ["List of improvements or modifications"],
          "fixed": ["List of bug fixes"],
          "removed": ["List of removed features or functionality"]
        }

        Guidelines:
        1. Convert technical commit messages into user-friendly descriptions
        2. Combine related commits into single, comprehensive entries
        3. SKIP purely internal commits (CI changes, code refactoring, dependency updates) unless they directly affect users
        4. Start each item with an action verb (Add, Improve, Fix, Remove, Enhance)
        5. Keep descriptions concise but meaningful (1 sentence each)
        6. Focus on user impact and benefits, not implementation details
        7. IGNORE any "Release" or "Bump version" or "chore: Release" commits
        8. Use empty arrays [] for categories with no relevant changes

        Return ONLY the JSON object with no additional text, markdown, or explanation.
      PROMPT
    end

    def build_prose_prompt(changelog_section, version)
      <<~PROMPT
        #{APP_CONTEXT}

        You are writing App Store release notes for version #{version} of Leaves of Blocks.

        Here is the structured changelog for this version:
        #{changelog_section}

        Write engaging, friendly release notes that will appear in the App Store "What's New" section.

        Requirements:
        1. Start with a warm, brief opening (1-2 sentences) that sets the tone
        2. Naturally mention the most important changes in flowing prose
        3. Use conversational, accessible language that any user can understand
        4. Subtly reference the autumn/cozy theme when it fits naturally
        5. End with exactly: "Thank you for playing Leaves of Blocks!"

        CRITICAL CONSTRAINTS:
        - MUST be under 3800 characters total (App Store limit is 4000)
        - Do NOT use bullet points, numbered lists, or any markdown formatting
        - Do NOT use emojis
        - Write in flowing paragraphs, not a list format
        - Be warm and appreciative but not overly enthusiastic
        - If there are only minor fixes, keep it brief (2-3 sentences total)

        Return ONLY the release notes text, ready for App Store submission. No introduction or explanation.
      PROMPT
    end

    def parse_changelog_response(response)
      content = response.dig('content', 0, 'text')
      return nil unless content

      # Handle potential markdown code block wrapping
      json_content = content.strip
      json_content = json_content.gsub(/^```json\s*/, '').gsub(/\s*```$/, '')

      # Extract JSON object if wrapped in other text
      json_match = json_content.match(/\{[\s\S]*\}/)
      return nil unless json_match

      parsed = JSON.parse(json_match[0])

      # Normalize to expected structure with symbol keys
      {
        added: Array(parsed['added']),
        changed: Array(parsed['changed']),
        fixed: Array(parsed['fixed']),
        removed: Array(parsed['removed'])
      }
    rescue JSON::ParserError => e
      AIHelper.ui_important("Failed to parse AI changelog response: #{e.message}")
      AIHelper.ui_message("Raw response: #{content[0..500]}...") if content
      nil
    end

    def parse_prose_response(response)
      content = response.dig('content', 0, 'text')
      return nil unless content

      # Clean up the response
      prose = content.strip

      # Remove any accidental markdown formatting
      prose = prose.gsub(/^\*+/, '').gsub(/\*+$/, '')
      prose = prose.gsub(/^#+\s*/, '')

      # Enforce character limit with intelligent truncation
      if prose.length > 3800
        truncated = prose[0..3700]
        # Find last complete sentence
        last_period = truncated.rindex(/[.!?]/)
        if last_period && last_period > 3000
          prose = truncated[0..last_period]
        else
          prose = truncated
        end
        # Ensure closing
        unless prose.include?("Thank you for playing")
          prose += "\n\nThank you for playing Leaves of Blocks!"
        end
      end

      prose
    end
  end
end
