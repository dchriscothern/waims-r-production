library(here)

# Absolute paths (removes all ambiguity)
qmd_abs <- normalizePath(here::here("reports", "daily_readiness.qmd"),
                         winslash = "/", mustWork = TRUE)

out_dir_abs <- normalizePath(here::here("reports", "output"),
                             winslash = "/", mustWork = FALSE)
dir.create(out_dir_abs, recursive = TRUE, showWarnings = FALSE)

out_file <- paste0("daily_readiness_", format(Sys.Date(), "%Y%m%d"), ".html")

cmd <- quarto::quarto_path()

# Render via Quarto CLI
res <- system2(
  cmd,
  args = c(
    "render", shQuote(qmd_abs),
    "--output-dir", shQuote(out_dir_abs),
    "--output", shQuote(out_file)
  ),
  stdout = TRUE,
  stderr = TRUE
)
cat(paste(res, collapse = "\n"))

# Confirm output where we told it to go; if not, search and move it.
expected <- file.path(out_dir_abs, out_file)

if (!file.exists(expected)) {
  hits <- list.files(here::here(), pattern = paste0("^", out_file, "$"),
                     recursive = TRUE, full.names = TRUE)
  if (length(hits) == 0) {
    stop("Render finished but output HTML not found anywhere. Expected: ", expected)
  }
  # Move/copy the first hit to the expected location
  file.copy(hits[1], expected, overwrite = TRUE)
}

cat("\nFinal HTML: ", normalizePath(expected, winslash = "/"), "\n", sep = "")