# ==============================================================================
# WAIMS-R: Daily Readiness Report Generator
# ==============================================================================
#
# PURPOSE: Creates HTML readiness report from monitoring data.
#
# FORMULA ALIGNMENT:
#   This readiness formula mirrors WAIMS-Python (train_models.py) exactly.
#   Both systems use the same evidence-based weights so outputs are comparable.
#   If you change weights here, update train_models.py readiness scorer to match.
#
# EVIDENCE BASIS FOR WEIGHTS:
#   Sleep (15 pts):    Watson 2020/2021, Saw 2016 — strongest individual predictor
#   Soreness (10 pts): Espasa-Labrador 2023, Saw 2016 — top daily signal
#   Mood (5 pts):      Saw 2016 — meaningful but lower than sleep/soreness
#   Stress (5 pts):    Saw 2016
#   CMJ (15 pts):      Cormack 2008, Labban 2024 SR — neuromuscular fatigue
#   RSI (10 pts):      Bishop 2023 — strategy captures more than height alone
#   Schedule (10 pts): back-to-back / travel / days rest context
#
#   ACWR: CONTEXTUAL FLAG ONLY — not in score (Impellizzeri 2020, 2025 meta-analysis)
#   Note: R data uses fatigue_0_10 instead of stress_0_10 (same conceptual signal)
#
# USAGE:
#   source("scripts/simple_report.R")
#
# ==============================================================================

library(tidyverse)
library(lubridate)
library(glue)

cat("\n=== Generating Daily Readiness Report (WAIMS-R) ===\n\n")

# ==============================================================================
# 1. LOAD DATA
# ==============================================================================

# Load most recent data files (adjust date in filenames as needed)
# In production, use dynamic file discovery:
latest_file <- function(dir, pattern) {
  files <- list.files(dir, pattern = pattern, full.names = TRUE)
  if (length(files) == 0) return(NULL)
  files[order(files, decreasing = TRUE)][1]
}

wellness_file    <- latest_file("raw/wellness",    "_wellness.csv")
gps_file         <- latest_file("raw/gps",         "_gps_practice.csv")
force_plate_file <- latest_file("raw/force_plate", "_forceplate.csv")

if (is.null(wellness_file)) stop("No wellness CSV found in raw/wellness/")

wellness    <- read_csv(wellness_file, show_col_types = FALSE)
gps         <- if (!is.null(gps_file)) read_csv(gps_file, show_col_types = FALSE) else tibble()
force_plate <- if (!is.null(force_plate_file)) read_csv(force_plate_file, show_col_types = FALSE) else tibble()
roster      <- read_csv("ref/athlete_roster.csv", show_col_types = FALSE)

cat(glue("✓ Wellness: {nrow(wellness)} records | GPS: {nrow(gps)} | Force plate: {nrow(force_plate)}\n\n"))

# ==============================================================================
# 2. EVIDENCE-BASED READINESS FORMULA
# ==============================================================================
# Mirrors WAIMS-Python calculate_readiness_score() in train_models.py
# Both use the same weight structure for cross-system consistency

calculate_readiness_r <- function(
    sleep_hours,
    soreness,          # 0-10 scale
    mood,              # 0-10 scale
    fatigue,           # 0-10 scale (maps to stress in Python system)
    cmj_height_cm = NA,
    rsi_mod = NA,
    is_back_to_back = 0,
    travel_flag = 0,
    days_rest = 3,
    time_zone_diff = 0,
    unrivaled_flag = 0,
    sleep_quality = 5   # 0-10 if tracked, else default 5
) {
  score <- 0

  # ── Subjective Wellness (35 pts total) ──────────────────────────────────────
  # Sleep: 15 pts (Watson 2020/2021, Saw 2016 — strongest individual predictor)
  sleep_pts <- min(15, (sleep_hours / 8.0) * 10 + (sleep_quality / 10) * 5)
  score <- score + sleep_pts

  # Soreness: 10 pts inverse (Espasa-Labrador 2023, top daily signal)
  score <- score + ((10 - soreness) / 10) * 10

  # Mood: 5 pts (Saw 2016)
  score <- score + (mood / 10) * 5

  # Fatigue/Stress: 5 pts inverse (Saw 2016; fatigue_0_10 maps to stress in Python)
  score <- score + ((10 - fatigue) / 10) * 5

  # ── Force Plate / Neuromuscular (25 pts) ────────────────────────────────────
  # CMJ: 15 pts (Cormack 2008, Labban 2024 SR+MA)
  # 32cm = solid WNBA guard/forward baseline (Bishop 2023 framework)
  if (!is.na(cmj_height_cm) && cmj_height_cm > 0) {
    score <- score + min(15, (cmj_height_cm / 32) * 15)
  } else {
    score <- score + 10  # Neutral if not tested today
  }

  # RSI-modified: 10 pts (Bishop 2023: strategy > height alone)
  # 0.45 = good WNBA benchmark
  if (!is.na(rsi_mod) && rsi_mod > 0) {
    score <- score + min(10, (rsi_mod / 0.45) * 10)
  } else {
    score <- score + 7  # Neutral if not tested
  }

  # ── Schedule Context (10 pts) ────────────────────────────────────────────────
  # Condensed schedule literature, Morikawa 2022
  schedule_pts <- 10
  if (is_back_to_back)              schedule_pts <- schedule_pts - 4
  if (travel_flag) {
    tz_penalty <- min(3, abs(time_zone_diff) * 1.5)
    schedule_pts <- schedule_pts - tz_penalty
  }
  if (days_rest <= 1)               schedule_pts <- schedule_pts - 2
  if (unrivaled_flag)               schedule_pts <- schedule_pts - 2  # Transition load
  score <- score + max(0, schedule_pts)

  # ── Clamp to 0-100 ───────────────────────────────────────────────────────────
  return(round(max(0, min(100, score)), 1))
}

# ==============================================================================
# 3. CALCULATE TODAY'S READINESS
# ==============================================================================

# Ensure date is a proper Date
wellness$date <- if (is.numeric(wellness$date)) {
  as.Date(wellness$date, origin = "1970-01-01")
} else {
  as.Date(wellness$date)
}

# Data date is the latest date available in the synthetic dataset
data_date <- max(wellness$date, na.rm = TRUE)

# Report date is when you generated the file
report_date <- Sys.Date()

# Join force plate (most recent test per athlete, not necessarily today)
# The R data generator exports force plate with force_plate_id (FP_001...)
# but wellness uses athlete_id (ATH_001...). Join through roster to bridge them.
latest_fp <- if (nrow(force_plate) > 0) {
  force_plate %>%
    arrange(desc(date)) %>%
    group_by(athlete_id) %>%   # athlete_id here = force_plate_id (FP_001)
    slice(1) %>%
    ungroup() %>%
    left_join(
      roster %>% select(athlete_id, force_plate_id),
      by = c("athlete_id" = "force_plate_id")
    ) %>%
    transmute(
      athlete_id     = athlete_id.y,  # real ATH_001 ID
      jump_height_cm = jump_height_cm,
      rsi_mod        = rsi_mod
    ) %>%
    filter(!is.na(athlete_id))
} else {
  tibble(athlete_id = character(), jump_height_cm = numeric(), rsi_mod = numeric())
}

readiness <- wellness %>%
  filter(date == data_date) %>%
  left_join(roster %>% select(athlete_id, display_name, position, role_tier),
            by = "athlete_id") %>%
  left_join(latest_fp, by = "athlete_id") %>%
  rowwise() %>%
  mutate(
    readiness_score = calculate_readiness_r(
      sleep_hours     = sleep_hours,
      soreness        = soreness_0_10,
      mood            = mood_0_10,
      fatigue         = fatigue_0_10,
      cmj_height_cm   = coalesce(jump_height_cm, NA_real_),
      rsi_mod         = coalesce(rsi_mod, NA_real_)
      # Schedule context: add is_back_to_back, travel_flag etc when schedule
      # table is available (from generate_database.py shared DB)
    )
  ) %>%
  ungroup() %>%
  mutate(
    status = case_when(
      readiness_score >= 80 ~ "GREEN",
      readiness_score >= 60 ~ "YELLOW",
      TRUE                  ~ "RED"
    ),
    # Specific flags (research-based thresholds from config.R)
    flag_sleep    = if_else(sleep_hours < 6.5,       "⚠ Low sleep",    ""),
    flag_soreness = if_else(soreness_0_10 >= 7,      "⚠ High soreness",""),
    flag_fatigue  = if_else(fatigue_0_10 >= 7,       "⚠ High fatigue", ""),
    flag_cmj      = if_else(!is.na(jump_height_cm) &
                             jump_height_cm < 26,    "⚠ CMJ low",      ""),
    # ACWR: display flag only (not scored) — Impellizzeri 2020
    acwr_note = "ACWR: contextual flag only — see correlation_explorer tab"
  ) %>%
  arrange(readiness_score)

cat(glue("✓ Readiness calculated for {nrow(readiness)} athletes\n"))
cat(glue("  Green: {sum(readiness$status=='GREEN')} | Yellow: {sum(readiness$status=='YELLOW')} | Red: {sum(readiness$status=='RED')}\n\n"))

# ==============================================================================
# 4. BUILD HTML REPORT
# ==============================================================================

html_content <- glue('
<!DOCTYPE html>
<html>
<head>
    <title>WAIMS Daily Readiness Report</title>
    <meta charset="UTF-8">
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            max-width: 1200px;
            margin: 20px auto;
            padding: 20px;
            background-color: #f8fafc;
            color: #1e293b;
        }}
        .header {{
            background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
            color: white;
            padding: 28px 32px;
            border-radius: 12px;
            margin-bottom: 28px;
        }}
        .header h1 {{ margin: 0; font-size: 28px; font-weight: 700; }}
        .header p  {{ margin: 8px 0 0 0; font-size: 15px; opacity: 0.75; }}
        .summary-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 16px;
            margin-bottom: 28px;
        }}
        .card {{
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.08);
            border-left: 4px solid #e2e8f0;
        }}
        .card.green {{ border-left-color: #16a34a; }}
        .card.yellow {{ border-left-color: #d97706; }}
        .card.red {{ border-left-color: #dc2626; }}
        .card h3 {{ margin: 0 0 6px 0; font-size: 12px; text-transform: uppercase;
                    letter-spacing: 0.05em; color: #64748b; }}
        .card .value {{ font-size: 40px; font-weight: 800; color: #1e293b; }}
        .card .sub   {{ font-size: 12px; color: #94a3b8; margin-top: 4px; }}
        table {{
            width: 100%;
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 1px 3px rgba(0,0,0,0.08);
            border-collapse: collapse;
        }}
        th {{
            background: #1e293b;
            color: white;
            padding: 13px 16px;
            text-align: left;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }}
        td {{ padding: 11px 16px; border-bottom: 1px solid #f1f5f9; font-size: 14px; }}
        tr:last-child td {{ border-bottom: none; }}
        tr:hover {{ background: #f8fafc; }}
        .badge {{
            display: inline-block;
            padding: 3px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 0.03em;
        }}
        .badge-green  {{ background: #dcfce7; color: #166534; }}
        .badge-yellow {{ background: #fef9c3; color: #854d0e; }}
        .badge-red    {{ background: #fee2e2; color: #991b1b; }}
        .flag {{ font-size: 11px; color: #ef4444; }}
        .research-note {{
            margin-top: 24px;
            padding: 16px 20px;
            background: #f1f5f9;
            border-radius: 8px;
            font-size: 12px;
            color: #475569;
            line-height: 1.6;
        }}
        .footer {{
            margin-top: 20px;
            text-align: center;
            color: #94a3b8;
            font-size: 12px;
        }}
    </style>
</head>
<body>
    <div class="header">
        <h1> Daily Readiness Report</h1>
        <p>Generated {format(report_date, "%A, %B %d, %Y")} | Data as of {format(data_date, "%Y-%m-%d")} | WAIMS-R Monitoring System</p>
    </div>

    <div class="summary-grid">
        <div class="card green">
            <h3>Ready — Full Training</h3>
            <div class="value">{sum(readiness$status=="GREEN")}</div>
            <div class="sub">Score ≥ 80</div>
        </div>
        <div class="card yellow">
            <h3>Monitor — Modified Training</h3>
            <div class="value">{sum(readiness$status=="YELLOW")}</div>
            <div class="sub">Score 60–79</div>
        </div>
        <div class="card red">
            <h3>Protect — Intervention Needed</h3>
            <div class="value">{sum(readiness$status=="RED")}</div>
            <div class="sub">Score &lt; 60</div>
        </div>
        <div class="card">
            <h3>Average Sleep</h3>
            <div class="value">{round(mean(readiness$sleep_hours, na.rm=TRUE), 1)}</div>
            <div class="sub">hrs (target 7.5+)</div>
        </div>
    </div>

    <h2 style="margin: 0 0 16px 0; font-size: 18px;">Player Readiness Status</h2>

    <table>
        <thead>
            <tr>
                <th>Player</th>
                <th>Pos</th>
                <th>Role</th>
                <th>Status</th>
                <th>Score</th>
                <th>Sleep</th>
                <th>Soreness</th>
                <th>Fatigue</th>
                <th>CMJ (cm)</th>
                <th>Flags</th>
            </tr>
        </thead>
        <tbody>
')

for (i in seq_len(nrow(readiness))) {
  p <- readiness[i, ]
  badge_class <- tolower(p$status)
  flags <- paste(
    p$flag_sleep, p$flag_soreness, p$flag_fatigue, p$flag_cmj
  ) %>% stringr::str_squish()
  cmj_display <- if (!is.na(p$jump_height_cm)) as.character(round(p$jump_height_cm, 1)) else "–"

  html_content <- paste0(html_content, glue('
            <tr>
                <td><strong>{p$display_name}</strong></td>
                <td>{p$position}</td>
                <td>{p$role_tier}</td>
                <td><span class="badge badge-{badge_class}">{p$status}</span></td>
                <td><strong>{p$readiness_score}</strong>/100</td>
                <td>{p$sleep_hours} h</td>
                <td>{p$soreness_0_10}/10</td>
                <td>{p$fatigue_0_10}/10</td>
                <td>{cmj_display}</td>
                <td class="flag">{flags}</td>
            </tr>
  '))
}

html_content <- paste0(html_content, glue('
        </tbody>
    </table>

    <div class="research-note">
        <strong>Formula basis (aligned with WAIMS-Python):</strong>
        Sleep 15pts (Watson 2020, Saw 2016) + Soreness 10pts + Mood 5pts + Fatigue 5pts
        + CMJ 15pts (Cormack 2008, Labban 2024) + RSI 10pts (Bishop 2023)
        + Schedule context 10pts + personal z-score modifier ±10pts. <br>
        <strong>ACWR: contextual flag only</strong> — not included in score.
        Impellizzeri et al. 2020 (BJSM) identified statistical coupling flaw;
        2025 meta-analysis (22 cohort studies, I²>75%) recommends \'use with caution as a tool\'.
    </div>

    <div class="footer">
        WAIMS Monitoring System &nbsp;|&nbsp; Generated: {format(Sys.time(), "%Y-%m-%d %H:%M:%S")}
    </div>
</body>
</html>
'))

# ==============================================================================
# 5. SAVE REPORT
# ==============================================================================

dir.create("reports/output", showWarnings = FALSE, recursive = TRUE)

report_file <- glue("reports/output/daily_readiness_{format(report_date, '%Y%m%d')}.html")
writeLines(html_content, report_file)

cat(glue("✓ Report saved: {report_file}\n"))
cat(glue("  Ready:    {sum(readiness$status == 'GREEN')}\n"))
cat(glue("  Monitor:  {sum(readiness$status == 'YELLOW')}\n"))
cat(glue("  Protect:  {sum(readiness$status == 'RED')}\n\n"))

if (.Platform$OS.type == "windows") {
  shell.exec(normalizePath(report_file))
  cat("✓ Opened in browser\n")
} else {
  cat(glue("Open in browser: file://{normalizePath(report_file)}\n"))
}

cat("\n=== Report Generation Complete ===\n")

