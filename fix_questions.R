# fix_questions.R  ---------------------------------------------------
# Regenerates expected_output in inst/extdata/questions.csv
# --------------------------------------------------------------

library(here)      # safe relative paths
library(readr)     # fast CSV
library(dplyr)     # data wrangling

# ------------ paths -------------------------------------------------
csv_path <- here::here("inst", "extdata", "questions.csv")
bak_path <- here::here("inst", "extdata", "questions_backup.csv")

if (!file.exists(csv_path))
  stop("questions.csv not found at: ", csv_path)

if (!file.exists(bak_path))
  file.copy(csv_path, bak_path, overwrite = FALSE)

# ------------ helper ------------------------------------------------
classify_object <- function(x) {
  if (is.matrix(x))             return("matrix")
  if (is.data.frame(x))         return("table")
  if (inherits(x, "gg"))        return("plot")
  if (is.list(x))               return("list")
  if (is.vector(x))             return("vector")
  "unknown"
}

# ------------ process ----------------------------------------------
questions <- read_csv(csv_path, show_col_types = FALSE)

fixed <- questions %>%
  rowwise() %>%
  mutate(
    .res = list(
      try(
        eval(parse(text = code), envir = new.env(parent = globalenv())),
        silent = TRUE
      )
    ),
    expected_output = {
      res <- .res[[1]]
      if (inherits(res, "try-error")) {
        expected_output           # keep original on error
      } else if (is.numeric(res) && length(res) == 1) {
        format(res, digits = 15, trim = TRUE)
      } else {
        classify_object(res)
      }
    }
  ) %>%
  select(-.res) %>%
  ungroup()

write_csv(fixed, csv_path)
message("✅  questions.csv updated. Backup stored as questions_backup.csv")
