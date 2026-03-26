# fix_questions.R  ---------------------------------------------------
# Regenerates expected_output in inst/extdata/questions.csv
#
# Prerequisites (development-only; not part of the package):
#   install.packages(c("here", "readr", "dplyr"))
# --------------------------------------------------------------

library(here)      # safe relative paths
library(readr)     # fast CSV
library(dplyr)     # data wrangling

source(here::here("R", "check_answer.R"), local = TRUE)

# ------------ paths -------------------------------------------------
csv_path <- here::here("inst", "extdata", "questions.csv")
bak_path <- here::here("inst", "extdata", "questions_backup.csv")

if (!file.exists(csv_path))
  stop("questions.csv not found at: ", csv_path)

if (!file.exists(bak_path))
  file.copy(csv_path, bak_path, overwrite = FALSE)

# ------------ process ----------------------------------------------
questions <- read_csv(csv_path, show_col_types = FALSE)

fixed <- questions %>%
  rowwise() %>%
  mutate(
    .res = list(
      .quiz_evaluate_code(
        user_code = code
      )
    ),
    expected_output = {
      res <- .res[[1]]
      if (!res$ok) {
        expected_output           # keep original on error
      } else if (is.numeric(res$result) && length(res$result) == 1) {
        format(res$result, digits = 15, trim = TRUE)
      } else {
        .classify_object_result(res$result)
      }
    }
  ) %>%
  select(-.res) %>%
  ungroup()

write_csv(fixed, csv_path)
message("✅  questions.csv updated. Backup stored as questions_backup.csv")
