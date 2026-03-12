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

## 2026-03-12 (C29)
Action: Added 4 questions (IDs 103-106) on Bonferroni correction (alpha/m),
  Benjamini-Hochberg FDR critical value (k/m * q), propensity score matching ATT
  (treated minus matched-control mean), and decision curve analysis net benefit
  (TP/N - FP/N * pt/(1-pt)).
Files:
  - inst/extdata/questions.csv (rows 103-106 appended)
  - tests/testthat/test-questions.R (row count 102 → 106)
  - README.md (updated exercise count 102 → 106, expanded topic list)
  - DESCRIPTION (expanded description with new topics)
  - inst/extdata/knowledge_repository.csv (3 new entries added)
Validation: pass (all 106 questions valid)
Commit: 8e22ddd
Next candidates:
- Add questions on G-computation / marginal standardization
- Add question on Kaplan-Meier log-rank test statistic
- Add question on sample size calculation for two-proportion z-test
- Add questions on calibration (Brier score, calibration slope)

## 2026-03-12 (C28)
Action: Added 3 questions (IDs 100-102) on Bayesian credible intervals (N(0,1)
  posterior upper bound via qnorm), C-statistic/AUC (concordant pair proportion),
  and intraclass correlation coefficient (ICC from mixed model variance components).
Literature: Lancet Digital Health 2026 guidance on discrimination vs calibration
  in clinical prediction models; ICC documentation update in `performance` R package
  (Feb 2026); Bayesian vs frequentist CI misinterpretation discussion from community.
Files:
  - inst/extdata/questions.csv (rows 100-102 appended)
  - tests/testthat/test-questions.R (row count 99 → 102)
  - README.md (updated exercise count 84 → 102, expanded topic list)
  - inst/extdata/knowledge_repository.csv (3 new entries added)
Validation: pass (all 102 questions valid)
Knowledge repo: updated
Commit: 9504a69
Next candidates:
- Add questions on Bonferroni correction and FDR (multiple testing)
- Add questions on decision curve analysis / Net Benefit
- Add question on propensity score matching (ATT vs ATE)
- Expand DESCRIPTION topics (ICC, AUC, Bayesian credible intervals)

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
