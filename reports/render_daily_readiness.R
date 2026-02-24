library(here)

cmd <- quarto::quarto_path()

# Always run Quarto from the reports/ directory so relative paths are stable
old <- getwd()
setwd(here::here("reports"))
on.exit(setwd(old), add = TRUE)

dir.create("output", recursive = TRUE, showWarnings = FALSE)

date_tag <- format(Sys.Date(), "%Y%m%d")
default_html <- here::here("reports", "output", "daily_readiness.html")
dated_html   <- here::here("reports", "output", paste0("daily_readiness_", date_tag, ".html"))
dated_pdf    <- here::here("reports", "output", paste0("daily_readiness_", date_tag, ".pdf"))

# Render into output/ with the default name (daily_readiness.html)
res <- system2(
  cmd,
  args = c("render", "daily_readiness.qmd", "--output-dir", "output"),
  stdout = TRUE,
  stderr = TRUE
)
cat(paste(res, collapse = "\n"))

if (!file.exists(default_html)) {
  stop("Expected output not found: ", default_html)
}

# Copy to dated HTML
file.copy(default_html, dated_html, overwrite = TRUE)
cat("\nFinal HTML: ", normalizePath(dated_html, winslash = "/"), "\n", sep = "")

# ---- HTML -> PDF (no LaTeX; uses Edge headless) ----
edge1 <- "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
edge2 <- "C:/Program Files/Microsoft/Edge/Application/msedge.exe"
edge <- if (file.exists(edge1)) edge1 else if (file.exists(edge2)) edge2 else NA_character_
if (is.na(edge)) stop("Edge not found. Install Edge or adjust msedge.exe path.")

html_abs <- normalizePath(dated_html, winslash = "/", mustWork = TRUE)
pdf_abs  <- normalizePath(dated_pdf,  winslash = "/", mustWork = FALSE)
file_url <- paste0("file:///", gsub("^/", "", html_abs))

if (file.exists(pdf_abs)) file.remove(pdf_abs)

args <- c(
  "--headless",
  "--disable-gpu",
  paste0("--print-to-pdf=", shQuote(pdf_abs)),
  shQuote(file_url)
)

out <- system2(edge, args = args, stdout = TRUE, stderr = TRUE)
cat(paste(out, collapse = "\n"))

if (!file.exists(pdf_abs)) stop("PDF was not created: ", pdf_abs)

cat("\nFinal PDF:  ", normalizePath(pdf_abs, winslash = "/"), "\n", sep = "")