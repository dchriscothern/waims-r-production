# reports/render_daily_readiness.R
library(here)

# absolute paths (no setwd needed)
input_qmd <- here::here("reports", "daily_readiness.qmd")
out_dir   <- here::here("reports", "output")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(input_qmd)) {
  stop("QMD not found: ", input_qmd)
}

cmd <- quarto::quarto_path()

# Render HTML into reports/output/
res <- system2(
  cmd,
  args = c("render", shQuote(input_qmd), "--output-dir", shQuote(out_dir)),
  stdout = TRUE,
  stderr = TRUE
)
cat(paste(res, collapse = "\n"))

default_html <- file.path(out_dir, "daily_readiness.html")
if (!file.exists(default_html)) {
  stop("Expected output not found: ", default_html)
}

dated_html <- file.path(
  out_dir,
  paste0("daily_readiness_", format(Sys.Date(), "%Y%m%d"), ".html")
)
file.copy(default_html, dated_html, overwrite = TRUE)

cat("\nFinal HTML: ", normalizePath(dated_html, winslash = "/"), "\n", sep = "")
