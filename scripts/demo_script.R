# ==============================================================================
# WAIMS-R: Interview Demo Script
# ==============================================================================
#
# PURPOSE: 5-minute demonstration for interviews
# Shows: Data generation, analysis, system capabilities
#
# HOW TO USE:
#   1. Open this file in RStudio
#   2. Run line-by-line (Ctrl+Enter) or section-by-section
#   3. Explain what you're doing as you go
#
# ==============================================================================

# ==============================================================================
# PART 1: System Setup (30 seconds)
# ==============================================================================

cat("\n=== WAIMS Monitoring System Demo ===\n")
cat("Professional Basketball Athlete Monitoring\n\n")

# Load system
library(tidyverse)
library(lubridate)

# Load configuration (shows research-validated thresholds)
source("scripts/config.R")

cat("\n✓ System loaded with research-validated thresholds\n")
cat("  - ACWR optimal: 0.8-1.3\n")
cat("  - Sleep critical: <6 hours\n")
cat("  - Asymmetry red flag: >15%\n\n")

# ==============================================================================
# PART 2: Generate Sample Data (1 minute)
# ==============================================================================

cat("=== Generating 83 Days of Monitoring Data ===\n\n")

# Generate realistic monitoring data
source("scripts/generate_sample_data.R")

cat("\n✓ Created monitoring data for 12 players\n")
cat("  - GPS/Practice load: 996 records\n")
cat("  - Daily wellness: 996 records\n")
cat("  - Force plate tests: 132 records\n")
cat("  - Wearable data: 996 records\n\n")

# ==============================================================================
# PART 3: Load and Explore Data (1 minute)
# ==============================================================================

cat("=== Loading Generated Data ===\n\n")

# Load data files
wellness <- read_csv("raw/wellness/20260221_wellness.csv", show_col_types = FALSE)
gps <- read_csv("raw/gps/20260221_gps_practice.csv", show_col_types = FALSE)
force_plate <- read_csv("raw/force_plate/20260221_forceplate.csv", show_col_types = FALSE)
roster <- read_csv("ref/athlete_roster.csv", show_col_types = FALSE)

cat("✓ Data loaded successfully\n\n")

# Show data structure
cat("Wellness data structure:\n")
glimpse(wellness)

cat("\nGPS data structure:\n")
glimpse(gps)

# ==============================================================================
# PART 4: Quick Analysis Examples (2 minutes)
# ==============================================================================

cat("\n=== Analysis Example 1: Today's Readiness ===\n\n")

# Who needs attention today?
todays_wellness <- wellness %>%
  filter(date == max(date)) %>%
  left_join(roster %>% select(athlete_id, display_name), by = "athlete_id") %>%
  mutate(
    # Flag high-risk players
    needs_attention = (sleep_hours < 6.5) | (soreness_0_10 >= 7) | (fatigue_0_10 >= 7)
  ) %>%
  arrange(desc(needs_attention), sleep_hours)

cat("Players needing attention today:\n")
print(todays_wellness %>% 
  filter(needs_attention) %>%
  select(display_name, sleep_hours, soreness_0_10, fatigue_0_10) %>%
  as.data.frame())

cat("\n")

# ---

cat("\n=== Analysis Example 2: Sleep Trends (Last 7 Days) ===\n\n")

# Weekly sleep patterns
sleep_trends <- wellness %>%
  filter(date >= max(date) - days(6)) %>%
  left_join(roster %>% select(athlete_id, display_name), by = "athlete_id") %>%
  group_by(display_name) %>%
  summarize(
    avg_sleep = round(mean(sleep_hours, na.rm = TRUE), 1),
    min_sleep = round(min(sleep_hours, na.rm = TRUE), 1),
    days_poor_sleep = sum(sleep_hours < 7, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(avg_sleep)

cat("Sleep patterns (last 7 days):\n")
print(head(sleep_trends, 5))

cat("\n")

# ---

cat("\n=== Analysis Example 3: Training Load Patterns ===\n\n")

# Load distribution across players
load_summary <- gps %>%
  filter(session_type == "PRACTICE") %>%
  left_join(
    roster %>% select(gps_id = athlete_id, display_name), 
    by = c("athlete_id" = "gps_id")
  ) %>%
  group_by(display_name) %>%
  summarize(
    sessions = n(),
    avg_minutes = round(mean(minutes, na.rm = TRUE), 1),
    total_distance_km = round(sum(distance_m, na.rm = TRUE) / 1000, 1),
    avg_player_load = round(mean(player_load, na.rm = TRUE), 1),
    .groups = "drop"
  ) %>%
  arrange(desc(total_distance_km))

cat("Training load summary:\n")
print(head(load_summary, 5))

cat("\n")

# ---

cat("\n=== Analysis Example 4: Force Plate Trends ===\n\n")

# Jump performance trends
jump_trends <- force_plate %>%
  left_join(
    roster %>% select(force_plate_id = athlete_id, display_name), 
    by = "force_plate_id"
  ) %>%
  rename(athlete_id = force_plate_id) %>%
  group_by(display_name) %>%
  arrange(date) %>%
  mutate(
    test_number = row_number(),
    baseline_jump = first(jump_height_cm),
    change_from_baseline = round(((jump_height_cm - baseline_jump) / baseline_jump) * 100, 1)
  ) %>%
  filter(test_number == max(test_number)) %>%  # Most recent test
  select(display_name, jump_height_cm, change_from_baseline, rsi_mod) %>%
  ungroup() %>%
  arrange(change_from_baseline)

cat("Recent force plate results (change from baseline):\n")
print(head(jump_trends, 5))

cat("\n")

# ==============================================================================
# PART 5: What This Demonstrates (30 seconds)
# ==============================================================================

cat("\n=== What This Demonstrates ===\n\n")

cat("✓ Multi-source data integration (GPS, wellness, force plates)\n")
cat("✓ Realistic monitoring data generation\n")
cat("✓ Research-validated thresholds (40+ peer-reviewed studies)\n")
cat("✓ Operational readiness assessment\n")
cat("✓ Production-ready R code\n")
cat("✓ Can be automated with Task Scheduler\n\n")

cat("=== Demo Complete ===\n")
cat("Time: ~5 minutes\n")
cat("Next: Can show wehoop integration or discuss research foundation\n\n")

# ==============================================================================
# BONUS: Save Summary Report
# ==============================================================================

# Create simple text summary
summary_text <- glue::glue("
WAIMS Monitoring System - Daily Summary
Generated: {Sys.time()}
========================================

ROSTER: {nrow(roster)} players
DATA RANGE: {min(wellness$date)} to {max(wellness$date)} ({length(unique(wellness$date))} days)

TODAY'S FLAGS:
- Players needing attention: {sum(todays_wellness$needs_attention, na.rm=TRUE)}
- Poor sleep (<7hrs): {sum(todays_wellness$sleep_hours < 7, na.rm=TRUE)}
- High soreness (≥7): {sum(todays_wellness$soreness_0_10 >= 7, na.rm=TRUE)}

WEEKLY TRENDS:
- Average sleep: {round(mean(sleep_trends$avg_sleep), 1)} hours
- Training sessions: {nrow(filter(gps, session_type == 'PRACTICE'))}
- Force plate tests: {nrow(force_plate)}

SYSTEM STATUS: All data processing complete ✓
")

cat(summary_text)

# Save to file
writeLines(summary_text, "reports/output/daily_summary.txt")
cat("\n✓ Summary saved to: reports/output/daily_summary.txt\n")

# ==============================================================================
# END OF DEMO
# ==============================================================================
