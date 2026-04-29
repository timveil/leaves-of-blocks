# GameCenterClient.rb
# Thin wrapper around the App Store Connect API endpoints for Game Center
# leaderboards and achievements. fastlane has no native action for these as
# of this writing (see https://github.com/fastlane/fastlane/issues/9082), so
# this client speaks JSON:API directly via Faraday using the JWT minted by
# `app_store_connect_api_key`.
#
# Reference docs:
#   https://developer.apple.com/documentation/appstoreconnectapi/game-center-leaderboards
#   https://developer.apple.com/documentation/appstoreconnectapi/game-center-achievements
#   Apple Tech Talk 111377 (Manage Game Center with the App Store Connect API)
#
# Idempotency: this client checks for an existing entry by vendor identifier
# before creating; matching entries are skipped (not patched). Re-running the
# lane is safe.

require 'faraday'
require 'json'

class GameCenterClient
  BASE_URL = 'https://api.appstoreconnect.apple.com'

  def initialize(jwt:)
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json, content_type: /\bjson$/
      f.adapter Faraday.default_adapter
    end
    @jwt = jwt
  end

  # MARK: - App + GameCenterDetail

  # Returns the App Store Connect app record for the given bundle id.
  def find_app(bundle_id:)
    res = get('/v1/apps', params: { 'filter[bundleId]' => bundle_id })
    apps = res.fetch('data', [])
    raise "No app found for bundle id #{bundle_id}" if apps.empty?
    apps.first
  end

  # Returns the gameCenterDetail for the app, creating it if absent.
  def get_or_create_game_center_detail(app_id:)
    res = @conn.get("/v1/apps/#{app_id}/gameCenterDetail") do |req|
      req.headers['Authorization'] = "Bearer #{@jwt}"
    end

    if res.status == 200 && res.body && res.body['data']
      detail = res.body['data']
      return detail if detail
    end

    UI.message("  Creating new gameCenterDetail for app #{app_id}")
    body = {
      data: {
        type: 'gameCenterDetails',
        relationships: {
          app: { data: { type: 'apps', id: app_id } }
        }
      }
    }
    created = post('/v1/gameCenterDetails', body: body)
    created.fetch('data')
  end

  # MARK: - Leaderboards

  def list_leaderboards(detail_id:)
    res = get("/v1/gameCenterDetails/#{detail_id}/gameCenterLeaderboards", params: { 'limit' => 200 })
    res.fetch('data', [])
  end

  def create_leaderboard(detail_id:, definition:)
    body = {
      data: {
        type: 'gameCenterLeaderboards',
        attributes: {
          referenceName: definition[:reference_name],
          vendorIdentifier: definition[:vendor_identifier],
          submissionType: definition[:submission_type],
          scoreSortType: definition[:score_sort_type],
          scoreFormat: definition[:score_format],
          scoreRangeStart: definition[:score_range_start],
          scoreRangeEnd: definition[:score_range_end]
        },
        relationships: {
          gameCenterDetail: { data: { type: 'gameCenterDetails', id: detail_id } }
        }
      }
    }
    post('/v1/gameCenterLeaderboards', body: body).fetch('data')
  end

  def list_leaderboard_localizations(leaderboard_id:)
    res = get("/v1/gameCenterLeaderboards/#{leaderboard_id}/localizations", params: { 'limit' => 200 })
    res.fetch('data', [])
  end

  def create_leaderboard_localization(leaderboard_id:, definition:)
    body = {
      data: {
        type: 'gameCenterLeaderboardLocalizations',
        attributes: {
          locale: definition[:locale],
          name: definition[:name],
          scoreFormatSuffix: definition[:score_format_suffix].to_s,
          scoreFormatSuffixSingular: definition[:score_format_suffix_singular].to_s
        },
        relationships: {
          gameCenterLeaderboard: { data: { type: 'gameCenterLeaderboards', id: leaderboard_id } }
        }
      }
    }
    post('/v1/gameCenterLeaderboardLocalizations', body: body).fetch('data')
  end

  # MARK: - Achievements

  def list_achievements(detail_id:)
    res = get("/v1/gameCenterDetails/#{detail_id}/gameCenterAchievements", params: { 'limit' => 200 })
    res.fetch('data', [])
  end

  def create_achievement(detail_id:, definition:)
    body = {
      data: {
        type: 'gameCenterAchievements',
        attributes: {
          referenceName: definition[:reference_name],
          vendorIdentifier: definition[:vendor_identifier],
          points: definition[:points],
          showBeforeEarned: definition[:shows_before_earned],
          repeatable: definition[:repeatable]
        },
        relationships: {
          gameCenterDetail: { data: { type: 'gameCenterDetails', id: detail_id } }
        }
      }
    }
    post('/v1/gameCenterAchievements', body: body).fetch('data')
  end

  def list_achievement_localizations(achievement_id:)
    res = get("/v1/gameCenterAchievements/#{achievement_id}/localizations", params: { 'limit' => 200 })
    res.fetch('data', [])
  end

  def create_achievement_localization(achievement_id:, definition:)
    body = {
      data: {
        type: 'gameCenterAchievementLocalizations',
        attributes: {
          locale: definition[:locale],
          name: definition[:name],
          beforeEarnedDescription: definition[:before_earned_description],
          afterEarnedDescription: definition[:after_earned_description]
        },
        relationships: {
          gameCenterAchievement: { data: { type: 'gameCenterAchievements', id: achievement_id } }
        }
      }
    }
    post('/v1/gameCenterAchievementLocalizations', body: body).fetch('data')
  end

  private

  def get(path, params: {})
    res = @conn.get(path, params) do |req|
      req.headers['Authorization'] = "Bearer #{@jwt}"
    end
    expect_success!(res, "GET #{path}")
    res.body
  end

  def post(path, body:)
    res = @conn.post(path) do |req|
      req.headers['Authorization'] = "Bearer #{@jwt}"
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end
    expect_success!(res, "POST #{path}")
    res.body
  end

  def expect_success!(res, label)
    return if (200..299).cover?(res.status)
    detail = res.body.is_a?(Hash) ? res.body['errors'].to_a.map { |e| e['detail'] || e['title'] }.join('; ') : res.body
    raise "#{label} failed (HTTP #{res.status}): #{detail}"
  end
end
