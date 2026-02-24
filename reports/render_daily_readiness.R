library(here)

cmd <- quarto::quarto_path()

# Always run Quarto from the reports/ directory so relative paths are stable
old <- getwd()
setwd(here::here("reports"))
on.exit(setwd(old), add = TRUE)

dir.create("output", recursive = TRUE, showWarnings = FALSE)

# Render into output/ with the default name (daily_readiness.html)
res <- system2(
  cmd,
  args = c("render", "daily_readiness.qmd", "--output-dir", "output"),
  stdout = TRUE,
  stderr = TRUE
)
cat(paste(res, collapse = "\n"))

default_html <- here::here("reports", "output", "daily_readiness.html")
dated_html   <- here::here("reports", "output", paste0("daily_readiness_", format(Sys.Date(), "%Y%m%d"), ".html"))

if (!file.exists(default_html)) {
  stop("Expected output not found: ", default_html)
}

file.copy(default_html, dated_html, overwrite = TRUE)

cat("\nFinal HTML: ", normalizePath(dated_html, winslash = "/"), "\n", sep = "")
