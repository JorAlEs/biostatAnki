# BioStatAnki <img src="man/figures/logo.png" align="right" height="115"/>

**BioStatAnki** is an R package that turns a set of flash cards into an interactive Shiny quiz for learning biostatistics through live coding.
For every card you write a short R expression, run it, and immediately see both the object returned and whether it matches the expected answer.

---

## Features

| Category | Details |
|----------|---------|
| **Exercises** | `inst/extdata/questions.csv` ships with **106 questions**.<br>• 40 numeric tasks (mean, median, variance, SD).<br>• Correlation, linear-model slope, survival analysis, Mendelian randomization, Bayesian inference (credible intervals), epidemiological measures (RR, OR, NNT, sensitivity, specificity, PPV, attributable risk), logistic regression, regularization (ridge penalty), causal inference (ATE, CATE), missing data (MCAR complete cases), two-sample t-test (pooled variance, t-statistic), competing risks (cumulative incidence), prediction model performance (C-statistic/AUC), mixed models (ICC), multiple testing (Bonferroni, FDR/BH), propensity score matching (ATT), and decision curve analysis (net benefit).<br>• Object tasks returning vectors or matrices—tagged with the keywords `vector` or `matrix`. |
| **Two-step workflow** | **Run code** executes the user expression in a safe environment and prints the result.<br>**Check answer** validates that result against the CSV, using numeric tolerance and keyword logic. |
| **Two-sheet app layout** | **Testing Area** for hands-on quiz execution and validation.<br>**Learning Area** with concise notes tied to tested concepts. |
| **Sandbox sheet** | Build mock datasets, run selected analyses, execute custom code, and get script snippets plus required libraries for reproducible workflows. |
| **Knowledge repository** | `inst/extdata/knowledge_repository.csv` stores explainers for R, Biostatistics, and Biostatistical Methods, linked to quiz coverage. |
| **Separated panes** | Shiny UI shows *Result* (object) and *Feedback* (correct / incorrect) in separate boxes. |
| **Random order** | Each session shuffles all cards once; no repeats until every card is seen. |
| **Robust validator** | `validate_questions()` executes every row and reports pass/fail. Runs locally and in CI. |
| **Self-healing CSV tool** | `fix_questions.R` recalculates numeric answers, tags objects with keywords, and creates a backup of the original CSV. |

---

## Documentation

Full API documentation is available at [biostatanki.github.io](https://github.com/jalcantara-espinosa/biostatAnki/wiki) (requires Pandoc for local builds).

## Installation

**Stable release** (v0.2.0):
```r
# from a local clone
devtools::install_local("path/to/biostatAnki")

# or directly from GitHub
remotes::install_github("jalcantara-espinosa/biostatAnki")
```

**Development version**:
```r
remotes::install_github("jalcantara-espinosa/biostatAnki", ref = "maintenance")
```

## Quick start

```r
library(BioStatAnki)

# launch the quiz
run_app()
```

## Programmatic API

```r
library(BioStatAnki)

# full data frame
qdf <- load_questions()
head(qdf)

# single question
get_question(12)

# answer checker
check_answer("median(c(5, 1, 9))", "5")   # TRUE
check_answer("1:10", "vector")             # TRUE (keyword)

# full validation (used in CI / pre-commit)
validate_questions()                       # All questions passed
```

## Development

### Setup

```r
# Use renv for reproducible development environment
renv::restore()  # Install development dependencies

# Run tests
devtools::test()

# Check package
devtools::check()

# Build documentation
devtools::document()  # Generate .Rd files from roxygen comments
pkgdown::build_site()  # Build full documentation site (requires Pandoc)
```

### Utilities

| Script / tool                      | Purpose                                                                                                                       |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **`fix_questions.R`**              | Evaluates every `code`, writes full-precision numeric answers, tags object outputs (`vector`, `matrix`) and backs up the CSV. |
| **Git pre-commit hook** (optional) | Runs `validate_questions()` and blocks commits that break the question set.                                                   |

### Daily LinkedIn draft automation

Generate a post draft from yesterday's GitHub changes:

```powershell
./generate_linkedin_post.ps1 -RepoPath . -OutputDir social/linkedin
```

Run a local daily loop (default 09:00 local time):

```powershell
./run_linkedin_daily_loop.ps1 -RepoPath . -OutputDir social/linkedin -RunImmediately
```

Or use GitHub Actions: `.github/workflows/linkedin-daily-draft.yaml` runs every day at `07:15 UTC` and commits updated drafts under `social/linkedin/`.

### Autonomous maintenance entrypoints

Two independent loop wrappers are available:

- ChatGPT/Codex loop: `./autonomous_loop.ps1`
- Claude loop (sidecar): `./autonomous_loop_claude.ps1`

Shared logic:

- Prompt template: `claude_cycle_prompt.txt`
- Daily external fetch: `daily_external_fetch.js`
- ChatGPT cycle runner: `run_cycle.js`
- Claude cycle runner: `run_cycle_claude.js`

Important: run only one autonomous loop at a time to avoid concurrent edits.

### Reproducible environment

The `renv.lock` file captures all package versions. Contributors should restore the environment with:
```r
renv::restore()
```

## Shiny app

This Shiny app is built from:

- **UI** — text area for code, action buttons, two output panes.
- **Server** — runs the code in a clean environment, stores the result, and validates it against `expected_output` using numeric tolerance and keyword recognition.
- **Reactive programming** keeps the interface in sync with user actions.

## License

MIT © 2025 Jorge Alcántara
