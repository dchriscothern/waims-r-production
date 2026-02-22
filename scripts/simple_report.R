# ==============================================================================
# WAIMS-R: Simple Report Generator
# ==============================================================================
#
# PURPOSE: Creates HTML reports from monitoring data
# OUTPUT: Daily readiness report (HTML format)
#
# USAGE:
#   source("scripts/simple_report.R")
#
# ==============================================================================

library(tidyverse)
library(lubridate)
library(glue)

cat("\n=== Generating Daily Readiness Report ===\n\n")

# ==============================================================================
# 1. LOAD DATA
# ==============================================================================

wellness <- read_csv("raw/wellness/20260221_wellness.csv", show_col_types = FALSE)
gps <- read_csv("raw/gps/20260221_gps_practice.csv", show_col_types = FALSE)
force_plate <- read_csv("raw/force_plate/20260221_forceplate.csv", show_col_types = FALSE)
roster <- read_csv("ref/athlete_roster.csv", show_col_types = FALSE)

# ==============================================================================
# 2. CALCULATE READINESS SCORES
# ==============================================================================

# Get today's data
today <- max(wellness$date)

readiness <- wellness %>%
  filter(date == today) %>%
  left_join(roster %>% select(athlete_id, display_name, position), by = "athlete_id") %>%
  mutate(
    # Simple readiness score (0-100)
    readiness_score = round(
      (sleep_hours / 8 * 30) +           # 30 points for sleep
      ((10 - soreness_0_10) / 10 * 25) + # 25 points for low soreness
      ((10 - fatigue_0_10) / 10 * 25) +  # 25 points for low fatigue
      (mood_0_10 / 10 * 20),             # 20 points for mood
      0
    ),
    
    # Status flags
    status = case_when(
      readiness_score >= 80 ~ "GREEN",
      readiness_score >= 60 ~ "YELLOW",
      TRUE ~ "RED"
    ),
    
    # Specific flags
    flag_sleep = if_else(sleep_hours < 6.5, "⚠️ Poor Sleep", ""),
    flag_soreness = if_else(soreness_0_10 >= 7, "⚠️ High Soreness", ""),
    flag_fatigue = if_else(fatigue_0_10 >= 7, "⚠️ High Fatigue", "")
  ) %>%
  arrange(readiness_score)

# ==============================================================================
# 3. CREATE HTML REPORT
# ==============================================================================

# Build HTML content
html_content <- glue('
<!DOCTYPE html>
<html>
<head>
    <title>WAIMS Daily Readiness Report</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            max-width: 1200px;
            margin: 20px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }}
        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }}
        .header h1 {{
            margin: 0;
            font-size: 32px;
        }}
        .header p {{
            margin: 10px 0 0 0;
            font-size: 18px;
            opacity: 0.9;
        }}
        .summary-cards {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }}
        .card {{
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        .card h3 {{
            margin: 0 0 10px 0;
            color: #333;
            font-size: 14px;
            text-transform: uppercase;
        }}
        .card .value {{
            font-size: 36px;
            font-weight: bold;
            color: #667eea;
        }}
        table {{
            width: 100%;
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        th {{
            background: #667eea;
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: 600;
        }}
        td {{
            padding: 12px 15px;
            border-bottom: 1px solid #f0f0f0;
        }}
        tr:hover {{
            background-color: #f8f9fa;
        }}
        .status-red {{ 
            background-color: #fee; 
            color: #c00;
            padding: 4px 8px;
            border-radius: 4px;
            font-weight: bold;
        }}
        .status-yellow {{ 
            background-color: #ffc; 
            color: #880;
            padding: 4px 8px;
            border-radius: 4px;
            font-weight: bold;
        }}
        .status-green {{ 
            background-color: #efe; 
            color: #060;
            padding: 4px 8px;
            border-radius: 4px;
            font-weight: bold;
        }}
        .flag {{
            font-size: 12px;
            color: #c00;
        }}
        .footer {{
            margin-top: 30px;
            padding: 20px;
            background: white;
            border-radius: 8px;
            text-align: center;
            color: #666;
        }}
    </style>
</head>
<body>
    <div class="header">
        <h1>🏀 Daily Readiness Report</h1>
        <p>{format(today, "%A, %B %d, %Y")} | Off-Season Training</p>
    </div>
    
    <div class="summary-cards">
        <div class="card">
            <h3>Ready to Train</h3>
            <div class="value">{sum(readiness$status == "GREEN")}</div>
            <p style="color: #060;">Full training cleared</p>
        </div>
        <div class="card">
            <h3>Monitor Closely</h3>
            <div class="value">{sum(readiness$status == "YELLOW")}</div>
            <p style="color: #880;">Modified training recommended</p>
        </div>
        <div class="card">
            <h3>Needs Attention</h3>
            <div class="value">{sum(readiness$status == "RED")}</div>
            <p style="color: #c00;">Requires intervention</p>
        </div>
        <div class="card">
            <h3>Average Sleep</h3>
            <div class="value">{round(mean(readiness$sleep_hours), 1)}</div>
            <p style="color: #666;">hours (target: 8+)</p>
        </div>
    </div>
    
    <h2 style="margin: 30px 0 20px 0;">Player Readiness Status</h2>
    
    <table>
        <thead>
            <tr>
                <th>Player</th>
                <th>Position</th>
                <th>Status</th>
                <th>Score</th>
                <th>Sleep</th>
                <th>Soreness</th>
                <th>Fatigue</th>
                <th>Flags</th>
            </tr>
        </thead>
        <tbody>
')

# Add player rows
for (i in 1:nrow(readiness)) {
    player <- readiness[i, ]
    
    status_class <- tolower(player$status)
    
    flags <- paste(
        player$flag_sleep,
        player$flag_soreness,
        player$flag_fatigue
    ) %>% str_trim()
    
    html_content <- paste0(html_content, glue('
            <tr>
                <td><strong>{player$display_name}</strong></td>
                <td>{player$position}</td>
                <td><span class="status-{status_class}">{player$status}</span></td>
                <td>{player$readiness_score}/100</td>
                <td>{player$sleep_hours} hrs</td>
                <td>{player$soreness_0_10}/10</td>
                <td>{player$fatigue_0_10}/10</td>
                <td class="flag">{flags}</td>
            </tr>
    '))
}

# Close HTML
html_content <- paste0(html_content, '
        </tbody>
    </table>
    
    <div class="footer">
        <p><strong>WAIMS Monitoring System</strong> | Research-Validated Athlete Monitoring</p>
        <p>Generated: ', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '</p>
    </div>
</body>
</html>
')

# ==============================================================================
# 4. SAVE REPORT
# ==============================================================================

# Create output directory if needed
dir.create("reports/output", showWarnings = FALSE, recursive = TRUE)

# Save HTML file
report_file <- glue("reports/output/daily_readiness_{format(today, '%Y%m%d')}.html")
writeLines(html_content, report_file)

cat(glue("✓ Report saved: {report_file}\n"))
cat(glue("  - Players ready: {sum(readiness$status == 'GREEN')}\n"))
cat(glue("  - Needs monitoring: {sum(readiness$status == 'YELLOW')}\n"))
cat(glue("  - Needs attention: {sum(readiness$status == 'RED')}\n\n"))

# Open in browser (Windows)
if (.Platform$OS.type == "windows") {
  shell.exec(normalizePath(report_file))
  cat("✓ Report opened in browser\n")
} else {
  cat(glue("Open in browser: file://{normalizePath(report_file)}\n"))
}

cat("\n=== Report Generation Complete ===\n")

# ==============================================================================
# END OF SCRIPT
# ==============================================================================
