# Cycle Log — biostatAnki

_Append-only full history. The AI never reads this file — it reads CYCLE_STATE.md instead._

---

### Cycle 1 — 2026-03-10

**Timestamp:** 2026-03-10 (interactive session, pre-loop)

**Chosen issue:** `purrr::pmap()` used in `validate_questions()` but `purrr` absent from `DESCRIPTION` `Imports` — verified runtime failure for any user without purrr pre-loaded.

**Files changed:**
- `R/validate_questions.R` — replaced `purrr::pmap(list(...), fn)` with base R `Map(fn, ...)`
- `DESCRIPTION` — fixed malformed `Maintainer:` line (truncated email); corrected question count from "50" to "60"

**Validation result:** PASSED — `validate_questions(read.csv(...))` → all 60 questions passed ✅

**Commit hash:** (not committed — git setup pending; fallback loop will commit)

**Top next candidates:**
1. `test/testthat/` is non-standard — won't be found by `devtools::test()`; should be under `tests/testthat/`
2. `LazyData: true` in DESCRIPTION but no `data/` directory — spurious field, causes NOTE in R CMD check
3. No CI/CD — add `.github/workflows/R-CMD-check.yaml`
4. `fix_questions.R` uses `here`, `readr`, `dplyr` without declaring them anywhere
5. No `renv.lock` — reproducibility gap for contributors

---

### Cycle 2 — 2026-03-10

**Timestamp:** 2026-03-10

**Chosen issue:** `test/testthat/test-questions.R` in wrong directory — `test_check()` scans `tests/testthat/`, so zero tests were being discovered by `devtools::test()` and `R CMD check`.

**Files changed:**
- `tests/testthat/test-questions.R` — created (same content as `test/testthat/test-questions.R`)

**Validation result:** PASSED — `devtools::test()` → FAIL 0 | WARN 0 | SKIP 0 | PASS 1 ✅

**Commit hash:** 8680989

---

### Cycle 3 — 2026-03-10

**Timestamp:** 2026-03-10

**Chosen issue:** No CI/CD — tests existed but nothing ran them automatically on push/PR.

**Files changed:**
- `.github/workflows/R-CMD-check.yaml` — created (triggers on push to main/master/auto/**, PRs to main/master)

**Validation result:** PASSED — local `devtools::check()` → 0 errors ✅

**Commit hash:** fe7e874

---

### Cycle 4 — 2026-03-10

**Timestamp:** 2026-03-10

**Chosen issues (batch — all DESCRIPTION):**
1. WARNING: `httpuv` used via `httpuv::randomPort()` in `run_app.R` but not declared in `DESCRIPTION Imports`
2. NOTE: `LazyData: true` in DESCRIPTION but no `data/` directory
3. NOTE: `License: MIT` without `+ file LICENSE`

**Files changed:**
- `DESCRIPTION` — added `httpuv` to `Imports`; removed `LazyData: true`; changed `License: MIT` → `License: MIT + file LICENSE`
- `LICENSE` — replaced full MIT text with proper DCF stub

**Validation result:** PASSED — `devtools::check()` → 0 errors, 2 warnings, 2 notes ✅

**Commit hash:** bb22b40

---

### Cycle 5 — 2026-03-10

**Timestamp:** 2026-03-10

**Chosen issues (batch):**
1. WARNING: Non-ASCII emoji in `R/run_app.R` and `R/validate_questions.R`
2. WARNING: `validate_questions.Rd` missing `@param` documentation
3. NOTE: Non-standard top-level files and hidden dirs not excluded from build
4. Cleanup: `test/` directory redundant alongside `tests/`

**Files changed:**
- `R/run_app.R` — replaced `▶` and `•` with `\u25b6` and `\u2022`
- `R/validate_questions.R` — replaced `❌`/`✅` with `\u274c`/`\u2705`; added `@param` roxygen2 tags
- `man/validate_questions.Rd` — added `\arguments{}` block
- `.Rbuildignore` — created
- `test/` — deleted

**Validation result:** PASSED — `devtools::check()` → 0 errors | 0 warnings | 1 note ✅

**Commit hash:** 59c91aa

---

### Cycle 6 — 2026-03-10

**Timestamp:** 2026-03-10

**Chosen issues (batch):**
1. Test suite thin — only 1 test
2. No `NEWS.md`

**Files changed:**
- `tests/testthat/test-questions.R` — expanded from 1 to 14 test cases covering all exported functions
- `NEWS.md` — created

**Validation result:** PASSED — `devtools::test()` → PASS 19; `devtools::check()` → 0 errors | 0 warnings | 1 note ✅

**Commit hash:** dc831be

---

### Cycle 7 — 2026-03-10

**Timestamp:** 2026-03-10

**Chosen issues (batch):**
1. README.md formatting inconsistencies
2. `fix_questions.R` missing dev-dep hint for contributors

**Files changed:**
- `README.md` — full rewrite
- `fix_questions.R` — added Prerequisites comment block

**Validation result:** PASSED — `devtools::check()` → 0 errors | 0 warnings | 1 note ✅

**Commit hash:** 18427f2

---

### Cycle 8 — 2026-03-10

**Timestamp:** 2026-03-10 12:19:30 +01:00

**Chosen issue:** `run_app()` had no test coverage.

**Files changed:**
- `tests/testthat/test-questions.R` — added `run_app` smoke test
- `REPO_FACTS.md` — updated

**Validation result:** PASSED — `devtools::test()` → PASS 30 ✅

**Commit hash:** 41afb6c

---

### Cycle 9 — 2026-03-10

**Timestamp:** 2026-03-10 12:32:56 +01:00

**Chosen issue:** `run_app()` failure-path tests missing.

**Files changed:**
- `R/run_app.R` — added `.has_namespace()`, `.get_app_dir()` internal wrappers
- `tests/testthat/test-questions.R` — added two failure-path tests

**Validation result:** PASSED — `devtools::test()` → PASS 32 ✅

**Commit hash:** 179db61

---

### Cycle 10 — 2026-03-10

**Timestamp:** 2026-03-10 13:05:18 +01:00

**Chosen issue:** `run_app()` returned visibly; docs promised invisible return.

**Files changed:**
- `R/run_app.R` — wrapped in `invisible(...)`
- `tests/testthat/test-questions.R` — added invisible return regression test

**Validation result:** PASSED — `devtools::test()` → PASS 34 ✅

**Commit hash:** 36fe5d7

---

### Cycle 11 — 2026-03-10

**Timestamp:** 2026-03-10 13:32:22 +01:00

**Chosen issue:** `validate_questions()` duplicated comparison logic; `tolerance` argument silently ignored.

**Files changed:**
- `R/check_answer.R` — extracted `.compare_expected_output()`
- `R/validate_questions.R` — removed duplicate `compare()`, now calls shared helper
- `tests/testthat/test-questions.R` — tolerance regression test

**Validation result:** PASSED — `devtools::test()` → PASS 36 ✅

**Commit hash:** 84d610e

---

### Cycle 12 — 2026-03-10

**Timestamp:** 2026-03-10 14:45:35 +01:00

**Chosen issue:** `validate_questions()` and `check_answer()` used different evaluation parents.

**Files changed:**
- `R/check_answer.R` — added `.quiz_eval_parent()` shared resolver
- `R/validate_questions.R` — switched to `.quiz_eval_parent()`
- `tests/testthat/test-questions.R` — stats/global-isolation regression tests

**Validation result:** PASSED — `devtools::test()` → PASS 38 ✅

**Commit hash:** a4208fa

---

### Cycle 13 — 2026-03-10

**Timestamp:** 2026-03-10 15:03:22 +01:00

**Chosen issue:** `.quiz_eval_parent()` fallback branch uncovered.

**Files changed:**
- `tests/testthat/test-questions.R` — fallback branch regression test

**Validation result:** PASSED — `devtools::test()` → PASS 39 ✅

**Commit hash:** ee50abc

---

### Cycle 14 — 2026-03-10

**Timestamp:** 2026-03-10 15:48:05 +01:00

**Chosen issue:** `.compare_expected_output()` crashed on NA expected output.

**Files changed:**
- `R/check_answer.R` — hardened for NA/missing expected outputs
- `tests/testthat/test-questions.R` — NA/logical/list edge case tests

**Validation result:** PASSED — `devtools::test()` → PASS 46 ✅

**Commit hash:** 998932a

---

### Cycle 15 — 2026-03-10

**Timestamp:** 2026-03-10 16:05:24 +01:00

**Chosen issue:** Expression-style expected outputs produced false negatives.

**Files changed:**
- `R/check_answer.R` — added `.safe_eval_expected_output()` and expression-string fallback
- `tests/testthat/test-questions.R` — expression-style regression tests

**Validation result:** PASSED — `devtools::test()` → PASS 52 ✅

**Commit hash:** ee40c33

---
