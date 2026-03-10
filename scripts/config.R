# ==============================================================================
# WAIMS-R: Athlete Availability Intelligence & Monitoring System
# Configuration Script
# ==============================================================================
#
# PURPOSE:
#   Central configuration for WAIMS-R production system. Defines all paths,
#   research-validated thresholds, and system settings used throughout pipeline.
#
# ARCHITECTURE NOTE:
#   WAIMS-R is the RESEARCH and DATA ENGINEERING layer.
#   WAIMS-Python (Streamlit dashboard) is the OPERATIONAL layer.
#   Both systems share the same SQLite database (waims_demo.db).
#   R writes wnba_benchmarks and gold_export CSVs; Python reads and displays them.
#
# DATA SOURCES (R layer):
#   - wehoop: WNBA Stats API wrapper (ESPN + stats.wnba.com)
#   - DuckDB warehouse: analytical queries across full seasons
#   - CSV exports from Kinexon/Catapult GPS hardware
#   - Force plate exports (Hawkin Dynamics, VALD, etc.)
#
# EVIDENCE HIERARCHY USED FOR THRESHOLDS:
#   Tier 1: SR/MA with GRADE, prospective cohort n>100, replicated
#   Tier 2: Prospective cohort n>50, or well-cited foundational studies
#   Tier 3: Small studies <50, exploratory, or not WNBA-specific
#   → Only Tier 1-2 evidence drives threshold values
#
# KEY DESIGN DECISION — ACWR:
#   ACWR is displayed as a CONTEXTUAL FLAG ONLY — not scored in readiness.
#   Evidence: Impellizzeri et al. 2020 (BJSM): statistical coupling flaw.
#   2025 meta-analysis (22 cohort studies, I²>75%): "use with caution as a tool".
#   No WNBA-specific ACWR cohort studies exist. Threshold zones kept for
#   display reference only.
#
# USAGE:
#   source("scripts/config.R")
#
# AUTHOR: Chris Cothern
# DATE: 2026-03-04 (updated from 2026-02-19)
# VERSION: 1.1.0
# ==============================================================================

library(fs)
library(glue)

# ==============================================================================
# PROJECT PATHS
# ==============================================================================

root_dir <- path_abs(".")

dirs <- list(
  raw_gps       = path(root_dir, "raw", "gps"),
  raw_force     = path(root_dir, "raw", "force_plate"),
  raw_wearables = path(root_dir, "raw", "wearables"),
  raw_wellness  = path(root_dir, "raw", "wellness"),
  ref           = path(root_dir, "ref"),
  warehouse     = path(root_dir, "warehouse"),
  gold_export   = path(root_dir, "gold_export"),
  reports_tpl   = path(root_dir, "reports", "templates"),
  reports_out   = path(root_dir, "reports", "output"),
  logs          = path(root_dir, "logs"),
  scripts       = path(root_dir, "scripts"),
  # Shared output folder — Python WAIMS reads benchmarks written here
  shared_export = path(root_dir, "gold_export", "shared")
)

purrr::walk(dirs, dir_create, recurse = TRUE)

db_path <- path(dirs$warehouse, "waims.duckdb")

# Path to Python WAIMS SQLite (for shared benchmark writes)
# Set this to your actual waims_demo.db path
python_db_path <- path(root_dir, "..", "waims-python", "waims_demo.db")

# ==============================================================================
# RESEARCH-VALIDATED THRESHOLDS
# ==============================================================================
# Thresholds are STARTING POINTS — tune after 3-6 weeks with your own
# athlete population. Intra-individual z-score comparison is more
# sensitive than population thresholds (Foster 1998, Cormack 2008).
#
# EVIDENCE GRADES:
#   ★★★ = Tier 1 (SR/MA or replicated prospective cohort, n>100)
#   ★★  = Tier 2 (prospective cohort n>50, or foundational study replicated)
#   ★   = Tier 3 (exploratory, small n, not WNBA-specific)

thresh <- list(

  # --------------------------------------------------------------------------
  # SLEEP THRESHOLDS — ★★★ Tier 1
  # --------------------------------------------------------------------------
  # Saw et al. 2016 (BJSM, 56-study SR): sleep strongest individual predictor
  # Watson et al. 2020/2021: sleep independently predicts injury in female athletes
  # Espasa-Labrador et al. 2023 (Sensors, women's basketball SR): most practical signal
  # Milewski et al. 2014: <6 hrs → elevated risk in adolescents
  #
  # Note: 7.5h target is conservative. WNBA travel schedule makes 8h optimal
  # difficult; 7h is operational floor for modification decisions.
  sleep_optimal  = 7.5,   # Target: full training cleared
  sleep_low      = 6.5,   # Yellow flag: modified training
  sleep_critical = 6.0,   # Red flag: intervention required

  # --------------------------------------------------------------------------
  # WELLNESS COMPOSITE Z-SCORE — ★★★ Tier 1
  # --------------------------------------------------------------------------
  # Saw et al. 2016: subjective measures correlate r=0.7 with objective fatigue
  # Foster 1998 (session RPE): intra-individual comparison foundational method
  # Espasa-Labrador 2023: wellness questionnaire most used in women's basketball
  #
  # Z-score captures "not herself" — more sensitive than absolute thresholds
  wellness_z_low    = -1.0,  # 1 SD below personal norm (yellow flag)
  wellness_z_critical = -2.0, # 2 SD below personal norm (red flag)

  # --------------------------------------------------------------------------
  # PAIN / SORENESS — ★★ Tier 2
  # --------------------------------------------------------------------------
  # Saw et al. 2016: soreness among top 3 daily wellness predictors
  # Clinical practice consensus: 3+ = monitor, 5+ = modify, 7+ = restrict
  pain_yellow = 3,     # Moderate: monitor closely
  pain_red    = 5,     # Significant: modify training
  pain_jump   = 2,     # 2+ point increase from previous day: concerning
  soreness_red = 7,    # Consistent with WAIMS-Python readiness formula

  # --------------------------------------------------------------------------
  # CMJ / FORCE PLATE — ★★★ Tier 1
  # --------------------------------------------------------------------------
  # Cormack et al. 2008 (IJSPP): foundational CMJ fatigue monitoring paper
  # Gathercole et al. 2015: CMJ drop thresholds for acute neuromuscular fatigue
  # Labban et al. 2024 (SR+MA): confirms daily CMJ sensitivity, replicated
  # Bishop et al. 2023: RSI-modified captures movement strategy, not just height
  #
  # Use % drop from individual 10-test rolling baseline, NOT population norms
  cmj_drop_yellow = -0.08,   # -8% from baseline: moderate fatigue (Gathercole 2015)
  cmj_drop_red    = -0.12,   # -12% from baseline: significant fatigue

  # RSI-modified thresholds (Bishop 2023 framework)
  rsi_drop_yellow = -0.10,   # -10% from baseline
  rsi_drop_red    = -0.15,   # -15% from baseline

  # --------------------------------------------------------------------------
  # BILATERAL ASYMMETRY — ★★ Tier 2
  # --------------------------------------------------------------------------
  # Bishop et al. 2018 (J Sports Sciences, 400+ citations): systematic review
  # McCall et al. 2022: asymmetry replication in basketball
  # Note: asymmetry threshold applicability to WNBA not directly validated — Tier 2
  asymmetry_yellow = 10,   # % bilateral asymmetry: caution
  asymmetry_red    = 15,   # High risk

  # --------------------------------------------------------------------------
  # GPS / LOAD Z-SCORES — ★★ Tier 2
  # --------------------------------------------------------------------------
  # Jaspers et al. 2017 (Sports Medicine SR): GPS load monitoring in football
  # Petway et al. 2020: basketball-specific load-injury relationship
  # Z-score from 28-day rolling baseline (intra-individual method)
  spike_z_yellow = 1.5,    # 1.5 SD above baseline: moderate spike
  spike_z_red    = 2.0,    # 2.0 SD above baseline: large spike

  # GPS drop flags (objective fatigue — Jaspers 2017)
  load_drop_yellow = -1.0,  # -1 SD below baseline: notable reduction
  load_drop_red    = -2.0,  # -2 SD below baseline: severe reduction

  # --------------------------------------------------------------------------
  # ACWR — CONTEXTUAL DISPLAY ZONES ONLY (★★ for zone display, NOT for scoring)
  # --------------------------------------------------------------------------
  # Gabbett 2016 (BJSM, 2000+ citations): established original framework
  # Hulin et al. 2016: cricket replication of sweet spot concept
  # *** IMPORTANT LIMITATION ***
  # Impellizzeri et al. 2020 (BJSM): statistical coupling problem identified
  # 2025 meta-analysis (22 cohort studies, I²>75%): "use with caution as a tool"
  # No WNBA-specific ACWR cohort studies published as of 2026
  # → ACWR values shown in UI for context; NOT included in readiness scoring
  acwr_underload    = 0.8,   # Below: detraining signal
  acwr_optimal_low  = 0.8,   # Sweet spot lower bound (Gabbett 2016)
  acwr_optimal_high = 1.3,   # Sweet spot upper bound
  acwr_caution      = 1.3,   # Caution zone begins
  acwr_high_risk    = 1.5,   # Flag for display; not a scoring threshold

  # --------------------------------------------------------------------------
  # SCHEDULE CONTEXT — ★★ Tier 2
  # --------------------------------------------------------------------------
  # Condensed schedule literature + Morikawa 2022
  # Back-to-back games: strongest contextual predictor in NBA/WNBA
  # Time zone shift >2 hrs: meaningful circadian disruption
  back_to_back_flag   = 1,   # Any back-to-back = flag
  days_rest_low       = 1,   # <2 days rest = reduced readiness expectation
  timezone_shift_flag = 2,   # >2 hr time zone change = travel fatigue flag

  # --------------------------------------------------------------------------
  # MENSTRUAL CYCLE — ★ Tier 3 (TRACK, DO NOT SCORE YET)
  # --------------------------------------------------------------------------
  # Espasa-Labrador et al. 2025, Barlow et al. 2024
  # Biology: luteal phase ligament laxity is well-established
  # Evidence grade: single studies n<50, no WNBA prospective cohort
  # Decision: track as logged variable; apply as clinical modifier only
  # DO NOT weight algorithmically until 2+ seasons of Wings-specific data
  cycle_luteal_start_day = 15,   # Approximate luteal phase start (varies by individual)
  cycle_luteal_end_day   = 28    # Track as context flag, not readiness modifier
)

# ==============================================================================
# READINESS SCORE FORMULA
# ==============================================================================
# Mirrors WAIMS-Python evidence-based formula for consistency.
# Both systems use the same weights so outputs are comparable.
#
# Evidence-based weights (Espasa-Labrador 2023, Saw 2016, Labban 2024):
#   Sleep:          15 pts  (strongest individual predictor — Watson 2020/2021)
#   Soreness:       10 pts  (Saw 2016: top 3 daily signal)
#   Mood:            5 pts
#   Stress:          5 pts  (Saw 2016: mood/stress lower weight than sleep/soreness)
#   CMJ:            15 pts  (Cormack 2008, Labban 2024 SR)
#   RSI-modified:   10 pts  (Bishop 2023: strategy > height alone)
#   Schedule:       10 pts  (back-to-back, travel, days rest)
#   Z-score modifier: ±10 pts (intra-individual deviation — Foster 1998)
#   GPS modifier:   ±6 pts  (Jaspers 2017, Petway 2020)
#   ACWR:           FLAG ONLY — extreme values get small modifier (see code)
#
# ACWR note: Applied as minor modifier at extremes only (>1.8 or <0.6),
# NOT as a scored component. See ACWR section above for rationale.

readiness_weights <- list(
  sleep_max      = 15,
  sleep_quality_max = 5,   # If sleep quality tracked separately
  soreness_max   = 10,
  mood_max       =  5,
  stress_max     =  5,
  cmj_max        = 15,
  rsi_max        = 10,
  schedule_max   = 10,
  zscore_modifier_max = 10,
  gps_modifier_max    =  6,
  acwr_role      = "contextual_flag_only"  # Not a scoring weight
)

# Reference values for normalisation (WNBA-calibrated)
readiness_ref <- list(
  sleep_target   = 8.0,    # hrs — optimal for elite athletes
  cmj_baseline   = 32.0,   # cm — solid WNBA guard/forward baseline
  rsi_baseline   = 0.45    # RSI-mod — good WNBA benchmark
)

# ==============================================================================
# SYSTEM SETTINGS
# ==============================================================================

settings <- list(
  baseline_window = 28,    # Days for z-score baselines (Gabbett 2016 chronic window)
  acute_window    =  7,    # ACWR acute period
  chronic_window  = 21,    # ACWR chronic period (3 weeks)

  # CMJ baseline: use rolling 10-test window, not fixed population norm
  cmj_baseline_tests = 10,

  # Expected testing frequency
  fp_expected_freq        = 7,    # Weekly force plate (standard)
  wellness_expected_freq  = 1,    # Daily wellness survey

  # Missing data tolerance
  max_days_missing_wellness = 3,

  # Traffic light categories
  status_green  = "G",   # Full training
  status_yellow = "Y",   # Modified (reduce volume/intensity)
  status_red    = "R",   # Limited (no extended live work)

  # Season context
  current_season     = 2026,
  season_start_date  = as.Date("2026-05-09"),  # Wings at Indiana Fever
  fiba_break_start   = as.Date("2026-08-31"),
  fiba_break_end     = as.Date("2026-09-16"),
  season_end_date    = as.Date("2026-09-23")   # Wings at Seattle Storm
)

# ==============================================================================
# DATA SOURCE CONFIGURATION
# ==============================================================================
# wehoop is R-WAIMS primary source; nba_api is Python WAIMS primary source.
# Both hit the same underlying stats.wnba.com data.

data_sources <- list(
  # Primary R source — stats.wnba.com via ESPN wrapper
  # Note: ESPN endpoint occasionally breaks; fall back to direct stats.wnba.com
  wehoop = list(
    primary   = TRUE,
    league_id = "10",       # WNBA
    team_id   = "1611661321", # Dallas Wings
    season    = 2026,       # Current season (started May 2026)
    fallback  = "nba_api"   # Python module as fallback
  ),

  # Python WAIMS source (nba_api, league_id='10')
  # More stable than wehoop — directly hits stats.wnba.com
  # Use for benchmarks and game logs in Python dashboard
  nba_api_python = list(
    primary   = FALSE,  # Primary for Python WAIMS; R uses wehoop
    install   = "pip install nba_api",
    league_id = "10",
    wnba_team_id = "1611661321"
  ),

  # Alternative for quick game score lookups
  balldontlie = list(
    url     = "https://api.balldontlie.io/wnba/v1/",
    note    = "Good free tier; real-time game scores; requires API key for history"
  ),

  # Gold standard — requires team access
  second_spectrum = list(
    available = FALSE,
    note = "WNBA league optical tracking — request access through Wings front office"
  )
)

# ==============================================================================
# FULL RESEARCH CITATIONS
# ==============================================================================

citations <- list(

  # ── Subjective Wellness ────────────────────────────────────────────────────
  saw_2016 = paste0(
    "Saw, A.E. et al. (2016). Monitoring the athlete training response: ",
    "subjective self-reported measures trump commonly used objective measures. ",
    "BJSM, 50(5), 281-291. [Tier 1 — 56-study SR, r=0.7 correlation with objective fatigue]"
  ),
  espasa_labrador_2023 = paste0(
    "Espasa-Labrador, J. et al. (2023). Methods for Monitoring Internal Training Load ",
    "in Women's Basketball: A Systematic Review. Sensors, 23(3). ",
    "[Tier 1 — ONLY SR specifically targeting women's basketball load monitoring]"
  ),
  watson_2020 = paste0(
    "Watson, A. et al. (2020). Sleep and injury in young athletes. ",
    "[Tier 1 — prospective, female athletes, sleep as independent injury predictor]"
  ),
  milewski_2014 = paste0(
    "Milewski, M.D. et al. (2014). Chronic lack of sleep is associated with increased ",
    "sports injuries. J Pediatric Orthop, 34(2), 129-133. [Tier 1, 500+ citations]"
  ),

  # ── Force Plate ────────────────────────────────────────────────────────────
  cormack_2008 = paste0(
    "Cormack, S.J. et al. (2008). Reliability and usefulness of measures taken ",
    "during the CMJ in elite and subelite Australian rules footballers. ",
    "IJSPP, 3(2), 161-175. [Tier 1 — foundational CMJ fatigue monitoring paper]"
  ),
  gathercole_2015 = paste0(
    "Gathercole, R. et al. (2015). Alternative CMJ analysis to quantify acute ",
    "neuromuscular fatigue. IJSPP, 10(1), 84-92. [Tier 2 — CMJ drop thresholds]"
  ),
  labban_2024 = paste0(
    "Labban, J.D. et al. (2024). CMJ monitoring systematic review and meta-analysis. ",
    "[Tier 1 — confirms daily CMJ sensitivity to recovery status]"
  ),
  bishop_2023 = paste0(
    "Bishop, C. et al. (2023). Framework for selecting force plate monitoring metrics. ",
    "[Tier 2 — RSI-modified captures strategy not just height]"
  ),
  bishop_2018 = paste0(
    "Bishop, C. et al. (2018). Effects of inter-limb asymmetries on physical and ",
    "sports performance: a systematic review. J Sports Sciences, 36(10), 1135-1144. ",
    "[Tier 2, 400+ citations — asymmetry and injury]"
  ),

  # ── Training Load / ACWR ───────────────────────────────────────────────────
  gabbett_2016 = paste0(
    "Gabbett, T.J. (2016). The training-injury prevention paradox. BJSM, 50(5), ",
    "273-280. [Tier 1, 2000+ citations — foundational ACWR paper; see limitations below]"
  ),
  hulin_2016 = paste0(
    "Hulin, B.T. et al. (2016). The acute:chronic workload ratio predicts injury. ",
    "BJSM. [Tier 2 — cricket replication of Gabbett sweet spot]"
  ),
  impellizzeri_2020 = paste0(
    "Impellizzeri, F.M. et al. (2020). Internal and external training load: 15 years on. ",
    "BJSM. [Tier 1 — identifies ACWR statistical coupling flaw; recommends against ",
    "standalone clinical use of ACWR]"
  ),
  acwr_meta_2025 = paste0(
    "2025 systematic review and meta-analysis of ACWR (22 cohort studies). ",
    "I²>75% heterogeneity. Conclusion: ACWR associated with injury risk but should be ",
    "used 'with caution as a tool'. No WNBA-specific cohort included."
  ),
  jaspers_2017 = paste0(
    "Jaspers, A. et al. (2017). Relationships between training load indicators and ",
    "training outcomes in professional football. Sports Medicine, 47(3), 559-575. ",
    "[Tier 2 — GPS feature importance SR]"
  ),
  petway_2020 = paste0(
    "Petway, A.J. et al. (2020). Training load and match-play demands in basketball. ",
    "[Tier 2 — basketball-specific, directly relevant]"
  ),

  # ── Consensus / Overarching ─────────────────────────────────────────────────
  bourdon_2017 = paste0(
    "Bourdon, P.C. et al. (2017). Monitoring Athlete Training Loads: Consensus Statement. ",
    "IJSPP, 12(Suppl 2), S2-161. [42 expert authors — overarching framework]"
  ),
  foster_1998 = paste0(
    "Foster, C. (1998). Monitoring training in athletes with reference to overtraining syndrome. ",
    "Med Sci Sports Exerc, 30(7), 1164-1168. [Tier 1, foundational session-RPE method]"
  ),

  # ── Schedule / Back-to-Back ─────────────────────────────────────────────────
  morikawa_2022 = paste0(
    "Morikawa, L. et al. (2022). Back-to-back game effects in NBA/WNBA condensed schedules. ",
    "[Tier 2 — contextual schedule stress]"
  ),

  # ── Menstrual Cycle ─────────────────────────────────────────────────────────
  espasa_labrador_2025 = paste0(
    "Espasa-Labrador, J. et al. (2025). Menstrual cycle phase and injury risk in female ",
    "basketball players. [Tier 3 — n<50, single competition; track, do not score yet]"
  ),
  barlow_2024 = paste0(
    "Barlow, M. et al. (2024). Luteal phase and ligamentous injury risk in female athletes. ",
    "[Tier 3 — promising biology, insufficient WNBA-specific data]"
  )
)

# ==============================================================================
# LOGGING
# ==============================================================================

log_config <- list(
  level   = "INFO",
  console = TRUE,
  file    = TRUE
)

log_msg <- function(msg, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_line  <- glue("[{timestamp}] [{level}] {msg}")
  if (log_config$console) cat(log_line, "\n")
  if (log_config$file) {
    logfile <- path(dirs$logs, glue("system_{format(Sys.Date(), '%Y%m%d')}.log"))
    cat(log_line, "\n", file = logfile, append = TRUE)
  }
  invisible(NULL)
}

# ==============================================================================
# PRINT CONFIG
# ==============================================================================

print_config <- function() {
  log_msg("=== WAIMS-R MONITORING SYSTEM v1.1.0 ===")
  log_msg(glue("Root: {root_dir}"))
  log_msg(glue("Database: {db_path}"))
  log_msg(glue("Season: {settings$current_season} | Start: {settings$season_start_date}"))
  log_msg("=== THRESHOLDS (Evidence-Based) ===")
  log_msg(glue("Sleep critical: <{thresh$sleep_critical} hrs [Tier 1 — Watson 2020, Saw 2016]"))
  log_msg(glue("CMJ drop yellow: {thresh$cmj_drop_yellow*100}% from baseline [Tier 1 — Cormack 2008, Labban 2024]"))
  log_msg(glue("Asymmetry red: >{thresh$asymmetry_red}% [Tier 2 — Bishop 2018]"))
  log_msg("ACWR: CONTEXTUAL FLAG ONLY — not scored [Impellizzeri 2020, 2025 MA]")
  log_msg(glue("  Display zones: {thresh$acwr_optimal_low}–{thresh$acwr_optimal_high} optimal | >{thresh$acwr_high_risk} flag"))
  log_msg("=== SYSTEM READY ===")
  invisible(NULL)
}

# ==============================================================================
# PACKAGE CHECK
# ==============================================================================

check_packages <- function() {
  required_packages <- c(
    "tidyverse", "duckdb", "DBI", "lubridate", "janitor",
    "glue", "fs", "slider", "quarto", "gt", "wehoop"
  )
  missing <- required_packages[!required_packages %in% installed.packages()[, "Package"]]
  if (length(missing) > 0) {
    log_msg(glue("Missing packages: {paste(missing, collapse=', ')}"), "WARNING")
    log_msg("Install: install.packages(c('tidyverse','duckdb','DBI','lubridate','janitor','glue','fs','slider','quarto','gt','wehoop'))", "WARNING")
    return(FALSE)
  }
  log_msg("All required packages installed ✓")
  return(TRUE)
}

# ==============================================================================
# AUTO-RUN ON SOURCE
# ==============================================================================

check_packages()
print_config()

