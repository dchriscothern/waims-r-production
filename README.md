# AvailOps — Availability Operations (R Ops Pipeline)

Local-first, CSV-first availability and readiness reporting pipeline for pro basketball.  
Designed to be deployable on team-owned Windows hardware with reproducible runs via `renv` and automated execution via Windows Task Scheduler. Includes a portfolio-safe public case study module.

## What AvailOps Does

AvailOps converts availability and workload signals into daily operational outputs: a coach-friendly AM readiness report (HTML by default, printable to PDF), optional weekly review outputs, and machine-readable CSV exports (watchlist and trends). It is intentionally lightweight and deployable without an enterprise AMS, while remaining compatible with future integrations.

## Modules

### 1) Ops Pipeline (Internal Demo or Synthetic)

Inputs  
External Activity log (CSV canonical format; designed to map cleanly from Google Sheets or Forms)

Outputs  
GOLD_EXPORT/external_daily_gold.csv  
GOLD_EXPORT/watchlist_today.csv  
GOLD_EXPORT/team_trends_7d.csv  
reports/output/daily_readiness.html  
reports/output/daily_readiness_YYYYMMDD.html

Note  
If you need a PDF, open the HTML report and print to PDF. A Quarto PDF render can be added later if needed.

### 2) Public Case Study (Portfolio-Safe)

Uses public ESPN WNBA boxscore data via wehoop to generate an anonymized availability summary and an exec-ready PDF case study.

Outputs  
GOLD_EXPORT/public_wnba_2025_DAL_availability_anon.csv  
docs/example_outputs/Public_Case_Study_DAL_Anon_example.pdf

Player identities are anonymized as DAL25_P##. No private health or medical data is included.

## Quick Start

### 0) Install renv (first time)

```r
install.packages("renv")
```

### 1) Restore the project environment

From the project root:

```r
renv::restore()
```

### 2) Confirm Quarto is installed

This project renders reports with Quarto. Confirm Quarto is available:

```r
quarto::quarto_path()
```

If Quarto is not installed, download it from https://quarto.org/docs/get-started/

### 3) Render the daily readiness report (recommended)

Run the render script from the project root:

```bash
Rscript reports/render_daily_readiness.R
```

This will:  
Render reports/daily_readiness.qmd into reports/output/  
Create reports/output/daily_readiness.html  
Copy a dated version as reports/output/daily_readiness_YYYYMMDD.html

Alternative Quarto CLI (from project root):

```bash
quarto render reports/daily_readiness.qmd
```

## Operational Deployment (Windows)

Typical deployment pattern  
1. Clone repo to a stable location such as C:\AvailOps\  
2. Run renv::restore once  
3. Create a Windows Task Scheduler job to run daily  
Program: Rscript  
Arguments: reports\render_daily_readiness.R  
Start in: project root folder

## Notes

The daily readiness report is meant to be a quick staff-facing brief with key insights and a simple action list.  
The pipeline is CSV-first so it can start lightweight and still plug into a larger data ecosystem later.

## Privacy

Internal demo and synthetic modules contain no protected health information.  
Public case study uses anonymized player IDs and public-only game data.")