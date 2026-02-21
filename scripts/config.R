# ==============================================================================
# WAIMS-R: Athlete Availability Intelligence & Monitoring System
# Configuration Script
# ==============================================================================
#
# PURPOSE:
#   Central configuration file for WAIMS-R production system. Defines all paths,
#   research-validated thresholds, and system settings used throughout pipeline.
#
# USAGE:
#   source("scripts/config.R")
#   
# DEPENDENCIES:
#   - fs: File system operations
#   - glue: String interpolation
#   - purrr: Functional programming tools
#
# AUTHOR: Chris Cothern
# DATE: 2026-02-19
# VERSION: 1.0.0
# ==============================================================================

library(fs)
library(glue)

# ==============================================================================
# PROJECT PATHS
# ==============================================================================
# All paths are relative to project root. Use path_abs() to get absolute paths
# for reliable file system operations regardless of working directory.

# Get absolute path to project root
root_dir <- path_abs(".")

# Define all project directories in a named list for easy access
dirs <- list(
  # Raw data import folders (CSV exports from AMS platforms)
  raw_gps       = path(root_dir, "raw", "gps"),           # GPS/load data (Kinexon, Catapult)
  raw_force     = path(root_dir, "raw", "force_plate"),   # Force plate testing
  raw_wearables = path(root_dir, "raw", "wearables"),     # Wearable devices (optional)
  raw_wellness  = path(root_dir, "raw", "wellness"),      # Daily wellness surveys
  
  # Reference data (athlete roster, drill tags, etc.)
  ref           = path(root_dir, "ref"),
  
  # Data warehouse (DuckDB database storage)
  warehouse     = path(root_dir, "warehouse"),
  
  # Gold layer outputs (daily CSVs for consumption)
  gold_export   = path(root_dir, "gold_export"),
  
  # Reports (Quarto templates and rendered outputs)
  reports_tpl   = path(root_dir, "reports", "templates"),
  reports_out   = path(root_dir, "reports", "output"),
  
  # System logs
  logs          = path(root_dir, "logs"),
  
  # R scripts
  scripts       = path(root_dir, "scripts")
)

# Create all directories if they don't exist (safe - won't overwrite)
purrr::walk(dirs, dir_create, recurse = TRUE)

# Database file path
db_path <- path(dirs$warehouse, "waims.duckdb")

# ==============================================================================
# RESEARCH-VALIDATED THRESHOLDS
# ==============================================================================
# All thresholds are derived from peer-reviewed sport science literature.
# These are STARTING POINTS - tune after 3-6 weeks with YOUR athlete population.
#
# REFERENCES:
#   - Gabbett, T.J. (2016). BJSM, 50(5), 273-280. [ACWR methodology]
#   - Andrade et al. (2021). Sports Medicine. [ACWR in female basketball]
#   - Milewski et al. (2014). J Pediatric Orthop. [Sleep & injury]
#   - Chesterton et al. (2023). JSAMS. [Basketball-specific fatigue]
#   - Bishop et al. (2018). J Sports Sciences. [Asymmetry & injury]
#   - Gathercole et al. (2015). IJSPP. [CMJ drop & fatigue]

thresh <- list(
  # --------------------------------------------------------------------------
  # ACUTE:CHRONIC WORKLOAD RATIO (ACWR)
  # --------------------------------------------------------------------------
  # Definition: Ratio of 7-day acute load to 21-day chronic load average
  # Research: Gabbett (2016), Andrade et al. (2021)
  # 
  # Interpretation:
  #   - 0.8-1.3: Optimal "sweet spot" for training adaptation
  #   - <0.8: Potential detraining or insufficient stimulus
  #   - 1.3-1.5: Caution zone - load increasing rapidly
  #   - >1.5: High risk - 2-4x injury likelihood in female basketball
  acwr_optimal_low  = 0.8,   # Lower bound of optimal range
  acwr_optimal_high = 1.3,   # Upper bound of optimal range
  acwr_high_risk    = 1.5,   # Red flag threshold (immediate attention)
  
  # --------------------------------------------------------------------------
  # LOAD SPIKES (Z-SCORE METHOD)
  # --------------------------------------------------------------------------
  # Definition: Standard deviations above 28-day rolling baseline
  # Research: Based on Gabbett (2016) spike detection methodology
  #
  # How it works:
  #   - Calculate rolling 28-day mean and SD for each athlete
  #   - Z-score = (today's load - mean) / SD
  #   - Flags deviations from individual norm
  #
  # Thresholds:
  spike_z_yellow = 1.5,      # Moderate spike (1.5 SD above baseline)
  spike_z_red    = 2.0,      # Large spike (2.0 SD above baseline)
  
  # --------------------------------------------------------------------------
  # SLEEP THRESHOLDS
  # --------------------------------------------------------------------------
  # Research: Milewski et al. (2014), Chesterton et al. (2023)
  # 
  # Evidence:
  #   - <6 hours: 1.7x injury risk in basketball (Chesterton 2023)
  #   - <8 hours: Elevated risk in adolescents (Milewski 2014)
  #   - 7.5-8.5: Optimal for adult elite athletes
  sleep_optimal  = 7.5,      # Target sleep duration (hours)
  sleep_low      = 6.5,      # Yellow flag threshold
  sleep_critical = 6.0,      # Red flag threshold
  
  # --------------------------------------------------------------------------
  # WELLNESS COMPOSITE (Z-SCORE)
  # --------------------------------------------------------------------------
  # Research: Saw et al. (2016) - subjective measures correlate r=0.7 with 
  # objective fatigue markers
  #
  # How it works:
  #   - Composite score from sleep + inverse(fatigue + soreness)
  #   - Z-score captures deviation from personal baseline
  #   - Flags when athlete is "not themselves"
  wellness_z_low = -1.0,     # 1 SD below personal norm (yellow flag)
  
  # --------------------------------------------------------------------------
  # PAIN / SYMPTOM REPORTING
  # --------------------------------------------------------------------------
  # Scale: 0-10 (0 = no pain, 10 = worst imaginable)
  # 
  # Thresholds based on clinical practice:
  #   - 0-2: Normal post-training soreness
  #   - 3-4: Moderate symptoms (monitor closely)
  #   - 5+: Significant symptoms (modify training)
  pain_yellow = 3,           # Moderate symptoms threshold
  pain_red    = 5,           # Significant symptoms threshold
  pain_jump   = 2,           # 2+ point increase from baseline (concerning)
  
  # --------------------------------------------------------------------------
  # COUNTERMOVEMENT JUMP (CMJ) - NEUROMUSCULAR FATIGUE
  # --------------------------------------------------------------------------
  # Research: Gathercole et al. (2015), Rodriguez-Rosell et al. (2023)
  #
  # Evidence:
  #   - 8-12% CMJ drop indicates acute neuromuscular fatigue
  #   - Takeoff velocity more sensitive than jump height
  #   - Compare to rolling 10-test baseline
  cmj_drop_yellow = -0.08,   # -8% from baseline (moderate fatigue)
  cmj_drop_red    = -0.12,   # -12% from baseline (significant fatigue)
  
  # --------------------------------------------------------------------------
  # BILATERAL ASYMMETRY
  # --------------------------------------------------------------------------
  # Research: Bishop et al. (2018), McCall et al. (2022)
  #
  # Evidence:
  #   - >10%: Caution - may indicate compensation pattern
  #   - >15%: High risk - strongly predicts injury
  #   - Measured via force plate (left vs right leg)
  asymmetry_yellow = 10,     # Percent bilateral asymmetry (caution)
  asymmetry_red    = 15,     # High risk threshold
  
  # --------------------------------------------------------------------------
  # ACCUMULATION RATIO (ALTERNATIVE TO ACWR)
  # --------------------------------------------------------------------------
  # Simplified check: Is 7-day load elevated vs 21-day average?
  # Use when ACWR data is incomplete
  accum_ratio_yellow = 1.20, # 20% above 3-week average
  accum_ratio_red    = 1.40  # 40% above 3-week average
)

# ==============================================================================
# SYSTEM SETTINGS
# ==============================================================================
# Operational parameters for data processing and analysis

settings <- list(
  # --------------------------------------------------------------------------
  # ROLLING WINDOW LENGTHS
  # --------------------------------------------------------------------------
  # How many days to use for baseline calculations
  baseline_window = 28,      # 4 weeks for z-score baselines
  acute_window    = 7,       # ACWR acute period (last 7 days)
  chronic_window  = 21,      # ACWR chronic period (last 21 days = 3 weeks)
  
  # --------------------------------------------------------------------------
  # TESTING FREQUENCY
  # --------------------------------------------------------------------------
  # Expected days between force plate tests (used to flag missing data)
  fp_expected_freq = 7,      # Weekly testing is standard
  
  # --------------------------------------------------------------------------
  # MISSING DATA TOLERANCE
  # --------------------------------------------------------------------------
  # How many consecutive days of missing data before flagging concern
  max_days_missing_wellness = 3,  # Alert if athlete hasn't filled wellness >3 days
  
  # --------------------------------------------------------------------------
  # STATUS CATEGORIES
  # --------------------------------------------------------------------------
  # Traffic light system for daily training recommendations
  status_green  = "G",       # Full training plan
  status_yellow = "Y",       # Modified training (reduce volume/intensity)
  status_red    = "R"        # Limited training (no extended live work)
)

# ==============================================================================
# RESEARCH CITATIONS (FULL REFERENCES)
# ==============================================================================
# Keep citations accessible for documentation and staff education

citations <- list(
  acwr = "Gabbett, T.J. (2016). The training-injury prevention paradox: should athletes be training smarter and harder? BJSM, 50(5), 273-280. [2000+ citations]",
  
  acwr_female = "Andrade, R. et al. (2021). The Potential Role of Acute:Chronic Workload Ratio in Injury Prevention in Female Basketball Players. Sports Medicine.",
  
  sleep = "Milewski, M.D. et al. (2014). Chronic lack of sleep is associated with increased sports injuries in adolescent athletes. J Pediatric Orthop, 34(2), 129-133. [500+ citations]",
  
  sleep_basketball = "Chesterton, P. et al. (2023). Fatigue and injury risk in elite basketball: A systematic review. JSAMS, 26(3), 147-155.",
  
  wellness = "Saw, A.E. et al. (2016). Monitoring the athlete training response: subjective self-reported measures trump commonly used objective measures. BJSM, 50(5), 281-291.",
  
  cmj = "Gathercole, R. et al. (2015). Alternative countermovement-jump analysis to quantify acute neuromuscular fatigue. IJSPP, 10(1), 84-92.",
  
  asymmetry = "Bishop, C. et al. (2018). Effects of inter-limb asymmetries on physical and sports performance: a systematic review. J Sports Sciences, 36(10), 1135-1144. [400+ citations]",
  
  consensus = "Bourdon, P.C. et al. (2017). Monitoring Athlete Training Loads: Consensus Statement. IJSPP, 12(Suppl 2), S2-161. [42 expert authors]"
)

# ==============================================================================
# LOGGING CONFIGURATION
# ==============================================================================
# Controls how system messages are logged (console + file)

log_config <- list(
  level   = "INFO",          # Options: DEBUG, INFO, WARNING, ERROR
  console = TRUE,            # Print to console?
  file    = TRUE             # Write to log files?
)

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

#' Log Message with Timestamp
#' 
#' Writes timestamped log messages to console and/or file based on log_config.
#' 
#' @param msg Character. The message to log.
#' @param level Character. Log level (INFO, WARNING, ERROR, DEBUG).
#' @return NULL (invisible). Logs message as side effect.
#' 
#' @examples
#' log_msg("System starting...")
#' log_msg("Missing data detected", level = "WARNING")
#' log_msg("Database connection failed", level = "ERROR")
log_msg <- function(msg, level = "INFO") {
  # Format timestamp as YYYY-MM-DD HH:MM:SS
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  
  # Create formatted log line
  log_line <- glue("[{timestamp}] [{level}] {msg}")
  
  # Output to console if enabled
  if (log_config$console) {
    cat(log_line, "\n")
  }
  
  # Write to daily log file if enabled
  if (log_config$file) {
    # Create date-stamped log filename (one file per day)
    logfile <- path(dirs$logs, glue("system_{format(Sys.Date(), '%Y%m%d')}.log"))
    
    # Append to log file (creates if doesn't exist)
    cat(log_line, "\n", file = logfile, append = TRUE)
  }
  
  # Return nothing (invisibly)
  invisible(NULL)
}

#' Print Configuration Summary
#' 
#' Displays key system configuration values at startup for verification.
#' Useful for troubleshooting and confirming settings are correct.
#' 
#' @return NULL (invisible). Prints summary as side effect.
print_config <- function() {
  log_msg("=== WAIMS MONITORING SYSTEM ===")
  log_msg(glue("Root directory: {root_dir}"))
  log_msg(glue("Database: {db_path}"))
  
  log_msg("=== THRESHOLDS (Research-Validated) ===")
  log_msg(glue("ACWR optimal: {thresh$acwr_optimal_low} - {thresh$acwr_optimal_high}"))
  log_msg(glue("ACWR high risk: >{thresh$acwr_high_risk}"))
  log_msg(glue("Sleep critical: <{thresh$sleep_critical} hours"))
  log_msg(glue("CMJ drop yellow: {thresh$cmj_drop_yellow * 100}%"))
  log_msg(glue("Asymmetry red: >{thresh$asymmetry_red}%"))
  
  log_msg("=== SYSTEM READY ===")
  invisible(NULL)
}

# ==============================================================================
# SYSTEM CHECKS
# ==============================================================================

#' Check Required R Packages
#' 
#' Verifies all required packages are installed. If any are missing, logs
#' warning with installation instructions.
#' 
#' @return Logical. TRUE if all packages installed, FALSE otherwise.
check_packages <- function() {
  # List of required packages
  required_packages <- c(
    "tidyverse",    # Data manipulation (dplyr, ggplot2, etc.)
    "duckdb",       # Database engine
    "DBI",          # Database interface
    "lubridate",    # Date/time handling
    "janitor",      # Data cleaning
    "glue",         # String interpolation
    "fs",           # File system operations
    "slider",       # Rolling window calculations
    "quarto",       # Report generation
    "gt"            # Table formatting (for reports)
  )
  
  # Check which packages are NOT installed
  missing <- required_packages[!required_packages %in% installed.packages()[, "Package"]]
  
  # If any missing, log warning with install command
  if (length(missing) > 0) {
    log_msg(glue("Missing packages: {paste(missing, collapse = ', ')}"), "WARNING")
    log_msg("Install with: install.packages(c('tidyverse','duckdb','DBI','lubridate','janitor','glue','fs','slider','quarto','gt'))", "WARNING")
    return(FALSE)
  }
  
  # All packages installed
  log_msg("All required packages installed ✓")
  return(TRUE)
}

# ==============================================================================
# AUTOMATIC EXECUTION ON SOURCE
# ==============================================================================
# When this file is sourced, automatically run system checks and print config

# Check packages
check_packages()

# Print configuration summary
print_config()

# ==============================================================================
# END OF CONFIGURATION
# ==============================================================================
# All paths, thresholds, and helper functions are now loaded and ready to use
# in other scripts via: source("scripts/config.R")
