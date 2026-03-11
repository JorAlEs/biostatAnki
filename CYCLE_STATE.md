# Cycle State — biostatAnki

_Overwritten each cycle. Full history → CYCLE_LOG.md (AI never reads that file)._

## Done (do not repeat any of these)

- C1: purrr→Map in validate_questions; DESCRIPTION email + count fixed
- C2: test/ → tests/testthat/ (canonical location for devtools::test)
- C3: CI/CD .github/workflows/R-CMD-check.yaml added
- C4: DESCRIPTION: httpuv added to Imports; LazyData removed; License→MIT+file; LICENSE→DCF stub
- C5: Non-ASCII emoji→\uXXXX escapes; @param roxygen docs; .Rbuildignore created; test/ deleted
- C6: Test suite expanded to 52 tests; NEWS.md created
- C7: README rewritten; fix_questions.R dev prereqs comment added
- C8: run_app() smoke test (shiny::runApp + httpuv::randomPort mocked)
- C9: run_app() failure-path tests; .has_namespace()/.get_app_dir() internal wrappers added
- C10: run_app() invisible return contract fixed and tested
- C11: .compare_expected_output() extracted as shared helper; validate_questions() tolerance bug fixed
- C12: .quiz_eval_parent() shared eval parent for check_answer + validate_questions
- C13: .quiz_eval_parent() fallback branch regression test
- C14: .compare_expected_output() hardened for NA/missing expected outputs
- C15: .safe_eval_expected_output() — expression-string comparator fallback (c, list, matrix, :)
- C16: roxygen blocks moved to correct functions (check_answer, run_app); NAMESPACE now exports exactly 5 public fns; orphaned @examples removed
- C17: fix_questions.R dev dependencies added to Suggests (dplyr, here, readr); Version bumped 0.1.0→0.2.0; renv.lock generated

## Top Candidates

1. No renv.lock — reproducibility gap for contributors
2. Bump DESCRIPTION Version to 0.2.0
3. fix_questions.R uses here/readr/dplyr without declaration
4. pkgdown site for rendered documentation
5. @return / @examples missing from get_question.Rd and load_questions.Rd

## Last Cycle

Cycle 16 — 2026-03-11 — roxygen/NAMESPACE fix — commit 8103d57 — PASS 52
