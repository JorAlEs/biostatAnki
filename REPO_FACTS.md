# Repo Facts — biostatAnki

Stable confirmed facts. Update only when something here actually changes.

## Package

- **Name:** biostatAnki
- **Version:** 0.1.0
- **Purpose:** Shiny quiz app for learning biostatistics — users write R code to answer questions, app validates result against expected output (Anki-style)
- **License:** MIT + file LICENSE

## Tech Stack

- **Language:** R package (standard structure)
- **R minimum:** >= 3.6.0
- **Imports:** shiny, httpuv
- **Suggests:** knitr, rmarkdown, testthat (>= 3.0.0)
- **Docs:** roxygen2 (RoxygenNote: 7.3.2)
- **No renv.lock** — reproducibility gap (open candidate)

## Key Files

| File | Role |
|------|------|
| `R/run_app.R` | `run_app()` — launches Shiny app, uses `httpuv::randomPort()` |
| `R/check_answer.R` | `check_answer()` — evaluates user code vs expected output |
| `R/validate_questions.R` | `validate_questions()` — batch validates all questions via `Map()` |
| `R/load_questions.R` | `load_questions()` — reads `inst/extdata/questions.csv` |
| `R/get_question.R` | `get_question(id)` — retrieves single question |
| `inst/app/app.R` | Shiny UI + server |
| `inst/extdata/questions.csv` | 60 questions: id, question, code, expected_output |
| `fix_questions.R` | Dev utility — regenerates expected_output (uses here/readr/dplyr, undeclared) |

## Test Setup

- **Framework:** testthat edition 3
- **Entry point:** `tests/testthat.R` → `test_check("biostatAnki")`
- **Test file:** `tests/testthat/test-questions.R` — 32 tests covering all exported functions (including `run_app()` smoke and failure paths)
- **`test/` directory removed** (was non-standard duplicate)

## CI

- **GitHub Actions:** `.github/workflows/R-CMD-check.yaml` — triggers on push to main/master/auto/**, PRs to main/master
- **Runner:** ubuntu-latest, r-lib/actions standard setup

## Known Non-Blocking Issues (NOTEs in R CMD check)

- 1 note: timestamp verification (environmental, not a code issue)
- `.Rbuildignore` exists and covers non-standard top-level files and hidden dirs

## Open Candidates (as of Cycle 9)

1. No `renv.lock` — reproducibility gap for contributors
2. `validate_questions()` internal `compare()` duplicates logic from `check_answer()` — refactor opportunity
3. `run_app()` docs say return is invisible, but implementation returns `shiny::runApp()` directly
4. `DESCRIPTION` Version `0.1.0` — consider bumping to `0.2.0`
5. Consider `pkgdown` site for rendered documentation
