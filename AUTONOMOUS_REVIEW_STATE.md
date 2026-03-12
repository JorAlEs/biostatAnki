# Autonomous Review State

## 2026-03-11 (seed)
Action: Loop rebuilt from scratch. Previous cycles completed through C23.
Files: (none — seed entry)
Validation: n/a
Commit: d324053 (last manual commit)
Next candidates:
- test/ → tests/testthat/ migration (non-standard path)
- Remove LazyData: true from DESCRIPTION (no data/ directory)
- fix_questions.R undeclared dependencies (here, readr, dplyr)
- Expand test coverage for edge cases in check_answer()
- Improve question diversity: add more epidemiology / Bayesian topics

## 2026-03-11 (C24)
Action: Added 7 epidemiology questions (IDs 67–73) covering RR, OR, NNT,
  sensitivity, specificity, PPV, and attributable risk.
Files:
  - inst/extdata/questions.csv (rows 67–73 appended)
  - tests/testthat/test-questions.R (row count 66 → 73)
  - DESCRIPTION (updated description topics, removed hardcoded "60")
  - README.md (updated exercise count 60 → 73, expanded topic list)
Validation: all_questions_valid passes; load_questions row count updated
Next candidates:
- Expand check_answer() tests for NaN / Inf edge cases
- Add questions on logistic regression (log-odds, probability from logit)
- Add questions on t-test interpretation (p-value, confidence interval width)

## 2026-03-12 (C27)
Action: Added 3 questions (IDs 82–84) on two-sample t-test (pooled variance,
  t-statistic) and competing risks (crude CIF from Fine-Gray model context).
  Also added NaN/Inf edge-case tests for check_answer().
Literature: DAILY_LIT_CONTEXT 2026-03-11 competing risks entry (Fine-Gray
  subdistribution model; CIF vs Kaplan-Meier) and two-sample t-test follow-up
  from prior candidate list.
Files:
  - inst/extdata/questions.csv (rows 82–84 appended)
  - tests/testthat/test-questions.R (row count 81 → 84; NaN/Inf tests added)
  - README.md (updated exercise count 81 → 84, expanded topic list)
Validation: pass (all 84 questions valid)
Next candidates:
- Add questions on Bayesian credible intervals vs frequentist CI interpretation
- Add questions on AUC vs calibration (discrimination vs calibration)
- Add questions on mixed models (random intercepts, ICC)
- Expand DESCRIPTION topics to mention competing risks and t-tests

## 2026-03-11 (C26)
Action: Added 3 questions (IDs 79–81) on causal inference (ATE, CATE) and
  missing data (MCAR expected complete-case proportion).
Literature: arXiv:2603.03035 (Generalized Bayes placing priors on ATE/CATE)
  and CRAN Jan 2026 NMAR/rCISSVAE packages + r/statistics MCAR/MAR/MNAR discussion.
Files:
  - inst/extdata/questions.csv (rows 79–81 appended)
  - tests/testthat/test-questions.R (row count 78 → 81)
  - README.md (updated exercise count 78 → 81, expanded topic list)
Validation: pass (all 81 questions valid)
Commit: c0d90e6
Next candidates:
- Add questions on two-sample t-test (pooled SE, t-statistic)
- Add Fine-Gray CIF question (competing risks, subdistribution hazard)
- Remove LazyData: true from DESCRIPTION (no data/ directory)
- Expand check_answer() tests for NaN / Inf edge cases

## 2026-03-11 (C25)
Action: Added 2 questions (IDs 77–78) on logistic regression (log-odds to
  probability) and ridge regression L2 penalty computation.
Literature: CRAN Jan 2026 `gradLasso` package and community interest in
  regression shrinkage methods (LASSO vs ridge) and logistic model interpretation.
Files:
  - inst/extdata/questions.csv (rows 77–78 appended)
  - tests/testthat/test-questions.R (row count 76 → 78)
  - README.md (updated exercise count 73 → 78, expanded topic list)
Validation: pass (all 78 questions valid)
Commit: 1dd71c1
Next candidates:
- Expand check_answer() tests for NaN / Inf edge cases
- Add questions on t-test interpretation (p-value, two-sample t-statistic)
- Add questions on ATE/CATE (causal inference estimands)
- Add questions on missing data mechanism (MCAR/MAR/MNAR properties)
- Remove LazyData: true from DESCRIPTION (no data/ directory)
