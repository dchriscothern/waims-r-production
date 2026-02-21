# AvailOps — Availability Operations (R Ops Pipeline)

Local-first, CSV-first availability & readiness reporting pipeline for pro basketball.  
Designed to be deployable on team-owned hardware (Windows), with reproducible runs via `renv`, automated execution (Task Scheduler), and portfolio-safe public case study modules.

---

## What AvailOps Does

AvailOps converts disparate “availability signals” into daily operational outputs: a coach-friendly AM readiness PDF, a weekly review PDF, and machine-readable CSV exports (watchlist + trends). It is intentionally lightweight and deployable without an enterprise AMS, while remaining compatible with future integrations (Teamworks AMS, Whistle/Catapult, Kinexon exports).

---

## Modules

### 1) Ops Pipeline (Internal Demo / Synthetic)
**Inputs**
- External Activity log (CSV canonical format; designed to map cleanly from Google Sheets / Forms)

**Outputs**
- `GOLD_EXPORT/external_daily_gold.csv`
- `GOLD_EXPORT/watchlist_today.csv`
- `GOLD_EXPORT/team_trends_7d.csv`
- Daily PDFs (generated locally; not committed): `REPORTS/output/*.pdf`

### 2) Public Case Study (Portfolio-Safe)
Uses public ESPN WNBA boxscore data via `wehoop` to generate an anonymized availability summary and an exec-ready PDF case study.

**Inputs**
- Public ESPN boxscore data pulled via `wehoop` (local raw files are ignored)

**Outputs**
- `GOLD_EXPORT/public_wnba_2025_DAL_availability_anon.csv` ✅ safe to commit
- `docs/example_outputs/Public_Case_Study_DAL_Anon_example.pdf` ✅ safe to commit

> Player identities are anonymized as `DAL25_P##`. No private health/medical data is included.

---

## Quick Start

### 0) Install packages (first time)
```r
install.packages("renv")