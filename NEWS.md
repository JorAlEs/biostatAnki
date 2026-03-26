# biostatAnki News

## 0.3.0 (development)

### New features
- Added shared quiz-engine helpers: `evaluate_answer()` and
  `compare_answer_result()` now power package validation, app checking, and
  development tooling from one implementation.
- Added metadata-aware question-bank helpers:
  `load_knowledge_repository()`, `list_question_topics()`,
  `filter_questions()`, `sample_questions()`, and
  `get_question_explanation()`.
- Added authoring and coverage helpers:
  `validate_question_row()` for draft-question checks and
  `summarize_question_bank()` for topic/difficulty/result-type summaries.

### Improvements
- `load_questions()` can now append derived `section`, `topic`,
  `difficulty`, and `tags` metadata without changing the on-disk CSV format.
- `get_question()` can optionally return metadata and the paired explanation
  note from the knowledge repository.
- The Shiny app now supports topic filtering, progress display, and per-question
  explanations while reusing the package's shared evaluation logic.
- `.Rprofile` now skips automatic `renv` activation in non-interactive scripts
  unless `BIOSTATANKI_ACTIVATE_RENV=true` is set.
- README, vignette, and contributor docs updated to remove stale hard-coded
  question/test counts and reflect the new APIs.

## 0.2.1 (2026-03-11)

### Documentation
- Added `CONTRIBUTING.md`: contributor guide covering dev setup with renv,
  test commands, question authoring workflow, code-style rules, and PR
  submission steps.

## 0.2.0 (2026-03-11)

### New features
- Added `vignettes/getting-started.Rmd`: introductory vignette covering
  `load_questions()`, `get_question()`, `check_answer()`, `validate_questions()`,
  and `run_app()` with runnable examples.

### Improvements
- `fix_questions.R` dev-script prerequisites documented; `dplyr`, `here`, and
  `readr` added to `Suggests`.
- `get_question()` and `load_questions()` gain `@examples` roxygen blocks.
- pkgdown site initialized with `_pkgdown.yml`; GitHub Actions workflow added
  for automatic docs deployment to `gh-pages` on push to `main`.
- README enhanced with documentation link, version badge, renv setup
  instructions, and test/check command reference.

## 0.1.0 (2026-03-10)

### Bug fixes
- Replaced `purrr::pmap()` with base-R `Map()` in `validate_questions()` (purrr was not declared in `DESCRIPTION`).

### Improvements
- Fixed malformed `Maintainer:` field and corrected question count in `DESCRIPTION`.
- Moved tests from non-standard `test/testthat/` to `tests/testthat/` so `devtools::test()` discovers them.
- Added GitHub Actions workflow for R CMD check on push/PR.
- Added `httpuv` to `Imports`; removed spurious `LazyData: true` from `DESCRIPTION`.
- Fixed `License` field to `MIT + file LICENSE`; replaced full MIT text with proper DCF stub.
- Replaced non-ASCII emoji in source files with Unicode escapes (`\uXXXX`).
- Added `@param` roxygen2 documentation to `validate_questions()`.
- Created `.Rbuildignore` to exclude development-only files from the built package.
- Removed redundant `test/` directory (superseded by `tests/`).
- Expanded test suite: `load_questions()`, `check_answer()`, `get_question()`, and `validate_questions()` now covered.
