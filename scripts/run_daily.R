# Dallas Wings Availability Intelligence System
# Master Daily Runner
# Orchestrates: Ingest → Analytics → Reports

source("scripts/00_config.R")

log_msg("========================================")
log_msg("   DALLAS WINGS MONITORING SYSTEM")
log_msg("      Daily Automated Run")
log_msg("========================================")
log_msg(glue("Run started: {Sys.time()}"))

# ============================================================================
# PIPELINE EXECUTION WITH ERROR HANDLING
# ============================================================================

run_step <- function(script_name, description) {
  log_msg("")
  log_msg(glue(">>> STEP: {description}"))
  log_msg(glue(">>> Script: {script_name}"))
  
  script_path <- file.path("scripts", script_name)
  
  if (!file.exists(script_path)) {
    log_msg(glue("ERROR: Script not found: {script_path}"), "ERROR")
    return(FALSE)
  }
  
  result <- tryCatch({
    source(script_path, local = new.env())
    log_msg(glue("✓ {description} completed successfully"))
    TRUE
  }, error = function(e) {
    log_msg(glue("✗ {description} FAILED: {e$message}"), "ERROR")
    log_msg("Stack trace:", "ERROR")
    log_msg(paste(capture.output(traceback()), collapse = "\n"), "ERROR")
    FALSE
  }, warning = function(w) {
    log_msg(glue("⚠ {description} completed with warnings: {w$message}"), "WARNING")
    TRUE
  })
  
  return(result)
}

# ============================================================================
# STEP 1: DATA INGESTION
# ============================================================================

step1_success <- run_step(
  "01_ingest_to_duckdb.R",
  "Data Ingestion (RAW → Staging)"
)

if (!step1_success) {
  log_msg("FATAL: Ingestion failed - cannot proceed", "ERROR")
  log_msg(glue("Run ended: {Sys.time()}"))
  quit(status = 1)
}

# ============================================================================
# STEP 2: ANALYTICS & WATCHLIST
# ============================================================================

step2_success <- run_step(
  "02_build_gold_and_watchlist.R",
  "Analytics Pipeline (Staging → Gold + Watchlist)"
)

if (!step2_success) {
  log_msg("FATAL: Analytics failed - cannot generate reports", "ERROR")
  log_msg(glue("Run ended: {Sys.time()}"))
  quit(status = 1)
}

# ============================================================================
# STEP 3: REPORT GENERATION
# ============================================================================

step3_success <- run_step(
  "03_render_reports.R",
  "Report Generation (Quarto → HTML)"
)

if (!step3_success) {
  log_msg("WARNING: Report generation failed, but watchlist CSVs are available", "WARNING")
}

# ============================================================================
# COMPLETION SUMMARY
# ============================================================================

log_msg("")
log_msg("========================================")
log_msg("        RUN COMPLETE")
log_msg("========================================")

# Check outputs exist
outputs_to_check <- list(
  "Watchlist CSV" = file.path(DIRS$gold_export, "watchlist_daily.csv"),
  "AM Board CSV" = file.path(DIRS$gold_export, "am_readiness_board.csv"),
  "HTML Report" = file.path(DIRS$reports_out, glue("AM_Readiness_{format(Sys.Date(), '%Y-%m-%d')}.html"))
)

log_msg("Output Status:")
for (output_name in names(outputs_to_check)) {
  output_path <- outputs_to_check[[output_name]]
  if (file.exists(output_path)) {
    file_size <- file.size(output_path)
    file_time <- file.info(output_path)$mtime
    log_msg(glue("  ✓ {output_name}: {basename(output_path)} ({file_size} bytes, {format(file_time, '%H:%M:%S')})"))
  } else {
    log_msg(glue("  ✗ {output_name}: NOT FOUND"), "WARNING")
  }
}

log_msg("")
log_msg(glue("Run ended: {Sys.time()}"))
log_msg("========================================")

# ============================================================================
# EXIT WITH APPROPRIATE STATUS
# ============================================================================

if (step1_success && step2_success) {
  quit(status = 0)  # Success
} else {
  quit(status = 1)  # Failure
}
