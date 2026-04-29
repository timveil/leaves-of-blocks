# GameCenterConfig.rb
# Declarative source-of-truth for the App's Game Center leaderboards and
# achievements. The `setup_game_center` lane reads from here and creates or
# verifies entries in App Store Connect via the App Store Connect API.
#
# The vendor identifiers below MUST stay in sync with `GameCenterIDs` in
# LeavesOfBlocks/Services/Game/GameCenterService.swift.
#
# Achievement points across all entries must total <= 1000 per Apple's rules.

module GameCenterConfig
  BUNDLE_ID = APP_IDENTIFIER

  LEADERBOARDS = [
    {
      vendor_identifier: "lob.leaderboard.allTimeHigh",
      reference_name: "All-Time High Score",
      submission_type: "BEST_SCORE",
      score_sort_type: "DESCENDING",
      score_format: "INTEGER",
      score_range_start: "0",
      score_range_end: "10000000",
      localizations: [
        {
          locale: "en-US",
          name: "All-Time High Score",
          score_format_suffix: "",
          score_format_suffix_singular: ""
        }
      ]
    }
  ].freeze

  ACHIEVEMENTS = [
    {
      vendor_identifier: "lob.ach.firstClear",
      reference_name: "First Clear",
      points: 50,
      shows_before_earned: true,
      repeatable: false,
      localizations: [
        {
          locale: "en-US",
          name: "First Clear",
          before_earned_description: "Clear your first line.",
          after_earned_description: "You cleared your first line — every leaf finds its place."
        }
      ]
    },
    {
      vendor_identifier: "lob.ach.combo4",
      reference_name: "Combo Master",
      points: 100,
      shows_before_earned: true,
      repeatable: false,
      localizations: [
        {
          locale: "en-US",
          name: "Combo Master",
          before_earned_description: "Clear four or more lines in a single placement.",
          after_earned_description: "Four lines, one move — patience, then power."
        }
      ]
    },
    {
      vendor_identifier: "lob.ach.efficiencyAPlus",
      reference_name: "Efficiency: A+",
      points: 250,
      shows_before_earned: true,
      repeatable: false,
      localizations: [
        {
          locale: "en-US",
          name: "Efficient as Autumn",
          before_earned_description: "Finish a session with an Efficiency grade of A+.",
          after_earned_description: "Few wasted cells. The grid breathed easy under your hand."
        }
      ]
    },
    {
      vendor_identifier: "lob.ach.strategicMaster",
      reference_name: "Strategic: Master",
      points: 250,
      shows_before_earned: true,
      repeatable: false,
      localizations: [
        {
          locale: "en-US",
          name: "Strategic Master",
          before_earned_description: "Finish a session with a Strategy grade of Master.",
          after_earned_description: "Each block placed with intention — a quiet kind of mastery."
        }
      ]
    },
    {
      vendor_identifier: "lob.ach.score10k",
      reference_name: "Ten Thousand Leaves",
      points: 350,
      shows_before_earned: true,
      repeatable: false,
      localizations: [
        {
          locale: "en-US",
          name: "Ten Thousand Leaves",
          before_earned_description: "Reach a final score of 10,000 in a single session.",
          after_earned_description: "Ten thousand points — the orchard is full."
        }
      ]
    }
  ].freeze

  def self.total_achievement_points
    ACHIEVEMENTS.sum { |a| a[:points] }
  end

  # Sanity check at load time so misconfigurations surface immediately.
  if total_achievement_points > 1000
    raise "Game Center achievement points total #{total_achievement_points}; Apple's per-app limit is 1000."
  end
end
