# ==============================================================================
# WAIMS-R: Game Data Integration — wehoop Package
# ==============================================================================
#
# PURPOSE:
#   Fetches WNBA game data using wehoop (ESPN + stats.wnba.com wrapper).
#   Provides play-by-play, box scores, and player statistics.
#
# ARCHITECTURE NOTE — WEHOOP vs nba_api:
#   R-WAIMS uses wehoop (this file) as the primary game data source.
#   Python WAIMS uses nba_api (wnba_api.py) as its primary source.
#   Both hit the same underlying stats.wnba.com data.
#
#   WHY nba_api is more stable for Python:
#   - nba_api hits stats.wnba.com directly (no ESPN middleman)
#   - wehoop's ESPN endpoint can break when ESPN changes their API silently
#   - nba_api actively maintained on PyPI through Feb 2026
#   - For R, wehoop remains the best option (no R equivalent of nba_api quality)
#
#   If wehoop ESPN endpoint fails, use load_wnba_player_box() which pulls
#   from stats.wnba.com directly rather than the ESPN wrapper.
#
# CURRENT CONTEXT:
#   Date: March 2026 / Off-season → 2026 WNBA season starts May 9
#   Most recent completed season: 2025 (May–October 2025)
#   Current season: 2026 (starts May 9 at Indiana Fever)
#
# USAGE:
#   source("scripts/fetch_game_data.R")
#   game_data <- fetch_and_process_games("DAL", season = 2025, last_n_games = 5)
#
# AUTHOR: Chris Cothern
# DATE: 2026-03-04 (updated from 2026-02-19)
# VERSION: 1.2.0
# ==============================================================================

library(wehoop)
library(tidyverse)
library(lubridate)

source("scripts/config.R")

# ==============================================================================
# TEAM IDENTIFIER CONSTANTS
# ==============================================================================
# Dallas Wings identifiers across different API sources
# ESPN and stats.wnba.com use different identifiers — be explicit

DAL_TEAM_ID_WNBA   <- 1611661321   # Official WNBA team_id (stats.wnba.com)
DAL_TEAM_ID_ESPN   <- 16           # ESPN team_id (wehoop ESPN endpoint)
DAL_ABBREVIATIONS  <- c("DAL", "Dallas", "Dallas Wings", "Wings")

# ==============================================================================
# CORE DATA FETCH FUNCTIONS
# ==============================================================================

#' Fetch Team's Recent Games from wehoop
#'
#' Retrieves game statistics for Dallas Wings from ESPN API via wehoop.
#' Falls back to stats.wnba.com endpoint if ESPN endpoint fails.
#'
#' @param team_abbreviation Character. "DAL" for Dallas Wings.
#' @param season Integer. Season year. Default 2025 (most recent completed).
#'   Use 2026 once season starts (May 9, 2026).
#' @param last_n_games Integer. Number of recent games (default 10).
#'
#' @return Tibble with game statistics per player per game.
#'
#' @details
#' Available via wehoop box scores:
#'   minutes, points, rebounds, assists, steals, blocks,
#'   field_goal_pct, three_point_field_goals, plus_minus
#'
#' NOT available (requires Second Spectrum or Kinexon):
#'   distance, sprint counts, accelerations, player load
#'
#' @examples
#' # Most recent completed season
#' dal_2025 <- get_team_game_data("DAL", season = 2025, last_n_games = 10)
#'
#' # Full 2025 retrospective
#' dal_full <- get_team_game_data("DAL", season = 2025, last_n_games = 44)
#'
#' # 2026 season (available after May 9 tip-off)
#' dal_2026 <- get_team_game_data("DAL", season = 2026, last_n_games = 5)
get_team_game_data <- function(team_abbreviation = "DAL",
                                season = 2025,
                                last_n_games = 10) {

  log_msg(glue("Fetching game data: {team_abbreviation} | {season} season | last {last_n_games} games"))

  # Validate season range
  if (season < 2020 || season > 2026) {
    log_msg(glue("Season {season} outside expected range (2020-2026)"), "WARNING")
  }

  tryCatch({
    # Load WNBA player box scores for specified season
    # load_wnba_player_box() uses stats.wnba.com endpoint (more stable than ESPN)
    player_box <- load_wnba_player_box(seasons = season)

    if (nrow(player_box) == 0) {
      log_msg(glue("No data returned for season {season}. Season may not have started."), "WARNING")
      return(tibble())
    }

    # Filter to Dallas Wings — use multiple identifiers for robustness
    # ESPN column names vary by endpoint version
    team_games <- player_box %>%
      filter(
        team_id == DAL_TEAM_ID_WNBA |
        team_abbreviation %in% DAL_ABBREVIATIONS |
        team_short_display_name %in% c("Dallas", "Wings") |
        team_display_name %in% c("Dallas Wings")
      )

    if (nrow(team_games) == 0) {
      # Debug: show what teams are available
      available_teams <- player_box %>%
        distinct(team_id, team_display_name, team_abbreviation) %>%
        head(20)
      log_msg("No Dallas Wings records found. Available teams:", "WARNING")
      print(available_teams)
      return(tibble())
    }

    # Sort by date and take most recent n games per player
    team_games_filtered <- team_games %>%
      arrange(desc(game_date)) %>%
      group_by(athlete_display_name) %>%
      slice(1:last_n_games) %>%
      ungroup()

    # Standardize to WAIMS schema
    game_data_clean <- team_games_filtered %>%
      transmute(
        athlete_name     = athlete_display_name,
        athlete_id_espn  = as.character(athlete_id),
        date             = as.Date(game_date),
        opponent         = opponent_team_short_display_name,
        home_away        = team_home_away,
        season           = !!season,

        # Box score stats
        minutes_played   = as.numeric(minutes),
        points,
        rebounds         = coalesce(total_rebounds, rebounds),
        assists,
        steals,
        blocks,
        turnovers,
        fouls            = coalesce(fouls, personal_fouls),

        # Shooting
        fg_made          = field_goals_made,
        fg_attempted     = field_goals_attempted,
        fg_pct           = round(coalesce(field_goal_pct,
                             ifelse(field_goals_attempted > 0,
                                    field_goals_made / field_goals_attempted, NA)), 3),
        three_pt_made    = three_point_field_goals_made,
        three_pt_attempted = three_point_field_goals_attempted,
        ft_made          = free_throws_made,
        ft_attempted     = free_throws_attempted,

        plus_minus,
        session_type     = "GAME",
        team_score,
        opponent_score,
        team_winner
      )

    log_msg(glue("Retrieved {nrow(game_data_clean)} game records for {team_abbreviation}"))
    return(game_data_clean)

  }, error = function(e) {
    log_msg(glue("Error fetching game data: {e$message}"), "ERROR")
    log_msg("Troubleshooting: (1) internet connected? (2) season available? (3) try load_wnba_player_box() directly?", "ERROR")
    return(tibble())
  })
}


#' Calculate Game Load Proxy from Box Score
#'
#' Estimates physical demand from statistics. This is a PROXY only —
#' true game load requires Second Spectrum optical tracking or in-arena GPS.
#'
#' Formula: load_proxy = minutes * (1 + rebounds/10 + (steals + blocks)/5)
#' Basis: Weiss et al. 2017 (basketball load estimation from stats)
#'
#' For production use: request Second Spectrum access from Wings front office.
#' Second Spectrum provides WNBA-wide optical tracking (distance, speed zones,
#' acceleration counts) — replaces this proxy entirely.
#'
#' @param game_data Tibble from get_team_game_data()
#' @return Tibble with game_load_proxy and high_load_flag columns added
calculate_game_load <- function(game_data) {

  if (nrow(game_data) == 0) return(game_data)

  game_data_with_load <- game_data %>%
    mutate(
      # Load proxy — weights minutes by physical demand actions
      game_load_proxy = round(
        minutes_played * (1 + coalesce(rebounds, 0) / 10 +
                          (coalesce(steals, 0) + coalesce(blocks, 0)) / 5),
        1
      ),
      # Starters with high minutes or defensive load
      high_load_flag = as.integer(
        minutes_played >= 30 |
        (coalesce(steals, 0) + coalesce(blocks, 0)) >= 5
      ),
      # Flag back-to-back games (requires schedule context — see schedule table)
      # This is approximate: 2 games within 48 hours
      back_to_back_game = as.integer(
        !is.na(date) &
        lag(as.numeric(date - lag(date, default = date[1])), default = 99) <= 1
      )
    )

  log_msg(glue("Calculated game load proxy for {nrow(game_data_with_load)} records"))
  return(game_data_with_load)
}


#' Map ESPN Athlete IDs to Internal WAIMS IDs
#'
#' Links wehoop ESPN IDs to your internal athlete_id system.
#' Required for joining game data with GPS/wellness monitoring data.
#'
#' @param game_data Tibble with athlete_id_espn column
#' @param roster_mapping Tibble with athlete_id and athlete_id_espn columns
#' @return Tibble with internal athlete_id added
#'
#' @details
#' Create mapping file: ref/espn_id_mapping.csv
#' Format: athlete_id, athlete_id_espn, display_name
#' Get ESPN IDs from: get_team_game_data() → athlete_id_espn column
#'
#' NOTE: nba_api (Python) uses numeric player_id from stats.wnba.com
#' which differs from ESPN athlete_id. You need separate mappings for
#' Python WAIMS and R-WAIMS if using both systems.
map_athlete_ids <- function(game_data, roster_mapping) {

  game_data_mapped <- game_data %>%
    left_join(
      roster_mapping %>% select(athlete_id, athlete_id_espn),
      by = "athlete_id_espn"
    )

  unmapped <- game_data_mapped %>% filter(is.na(athlete_id))
  if (nrow(unmapped) > 0) {
    log_msg(glue("{nrow(unmapped)} records with unmapped athlete IDs"), "WARNING")
    unmapped %>%
      distinct(athlete_name, athlete_id_espn) %>%
      mutate(msg = glue("  Unmapped: {athlete_name} (ESPN ID: {athlete_id_espn})")) %>%
      pull(msg) %>%
      walk(~ log_msg(.x, "WARNING"))
  }

  return(game_data_mapped)
}


#' Export Game Data to Raw Folder
#'
#' Saves processed game data as CSV for pipeline ingestion.
#' File: raw/game_tracking/YYYYMMDD_wehoop_games.csv
#'
#' @param game_data Tibble with processed game statistics
#' @param output_date Date for filename (default today)
#' @return File path to saved CSV
export_game_data <- function(game_data, output_date = Sys.Date()) {

  game_tracking_dir <- path(dirs$raw_gps, "..", "game_tracking")
  dir_create(game_tracking_dir)

  filename <- glue("{format(output_date, '%Y%m%d')}_wehoop_games.csv")
  filepath <- path(game_tracking_dir, filename)

  write_csv(game_data, filepath)
  log_msg(glue("Exported: {filepath} ({nrow(game_data)} records, {min(game_data$date)} to {max(game_data$date)})"))
  return(filepath)
}


# ==============================================================================
# ALL-IN-ONE WRAPPER
# ==============================================================================

#' Fetch, Process, and Export Team Game Data
#'
#' @param team_abbreviation Character. "DAL" for Dallas Wings.
#' @param season Integer. Default 2025 (most recent completed season).
#'   Use 2026 after May 9, 2026 tip-off.
#' @param last_n_games Integer. Number of recent games.
#' @param roster_mapping Tibble with ID mapping (optional).
#'
#' @examples
#' # 2025 season retrospective (most recent complete data)
#' games_2025 <- fetch_and_process_games("DAL", season = 2025, last_n_games = 10)
#'
#' # 2026 season (after May 9 tip-off)
#' games_2026 <- fetch_and_process_games("DAL", season = 2026, last_n_games = 5)
#'
#' # With athlete ID mapping
#' mapping <- read_csv("ref/espn_id_mapping.csv")
#' games <- fetch_and_process_games("DAL", 2025, 10, roster_mapping = mapping)
fetch_and_process_games <- function(team_abbreviation = "DAL",
                                     season = 2025,
                                     last_n_games = 10,
                                     roster_mapping = NULL) {

  log_msg("=== FETCHING AND PROCESSING GAME DATA ===")
  log_msg(glue("Season: {season} | Games: {last_n_games}"))

  if (season == 2026) {
    log_msg("2026 season: available after May 9, 2026 tip-off (Wings at Indiana Fever)", "INFO")
  }

  game_data <- get_team_game_data(team_abbreviation, season, last_n_games)
  if (nrow(game_data) == 0) {
    log_msg("No game data retrieved", "ERROR")
    return(tibble())
  }

  game_data <- calculate_game_load(game_data)

  if (!is.null(roster_mapping)) {
    game_data <- map_athlete_ids(game_data, roster_mapping)
  } else {
    log_msg("No roster mapping — using ESPN IDs only. See ref/espn_id_mapping.csv", "WARNING")
  }

  export_game_data(game_data)
  log_msg("=== GAME DATA PROCESSING COMPLETE ===")
  return(game_data)
}


# ==============================================================================
# WHAT WEHOOP / WNBA STATS API PROVIDES vs WHAT IT DOESN'T
# ==============================================================================
#
# ✅ Available (box scores / stats.wnba.com):
#   - Minutes played, points, rebounds, assists, steals, blocks, turnovers
#   - Shooting percentages, free throws, plus/minus
#   - Game outcomes (W/L, final score)
#   - Play-by-play (via ESPN endpoint)
#   - Historical seasons (2019+)
#
# ❌ NOT available without hardware:
#   - Distance covered in-game (requires Second Spectrum or Kinexon)
#   - Sprint counts and speed zones
#   - Acceleration/deceleration counts
#   - Player load (mechanical load composite)
#   - Shot quality / defensive coverage metrics
#
# ⭐ TO UNLOCK TRUE GAME LOAD DATA:
#   1. Second Spectrum: official WNBA optical tracking — request through Wings FO
#   2. Kinexon in-arena GPS: if team has installed (non-standard for WNBA currently)
#   3. Sportradar advanced feeds: paid commercial license
#
# ==============================================================================
# 2026 SEASON CONTEXT
# ==============================================================================
#
# Dallas Wings 2026 schedule:
#   - Opener:    May 9 at Indiana Fever (road)
#   - Home debut: May 12 vs Atlanta Dream (College Park Center)
#   - AAC games: July 12 (CHI), Aug 7 (GSV), Aug 20 (IND)
#   - FIBA break: Aug 31 – Sep 16 (no WNBA games)
#   - Season end: Sep 23 at Seattle Storm
#
# Key players to track for Unrivaled → WNBA transition load:
#   - Paige Bueckers: Breeze BC (Unrivaled Jan-Mar 2026) → WNBA camp ~Apr 28
#   - Arike Ogunbowale: Mist BC (Unrivaled Jan-Mar 2026) → WNBA camp ~Apr 28
#   Both go from 3-on-3 (72ft court, 18s clock) directly into 5-on-5 training
#   Different movement patterns — monitor CMJ and load transitions carefully
