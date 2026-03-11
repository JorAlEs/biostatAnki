# biostatAnki News

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
