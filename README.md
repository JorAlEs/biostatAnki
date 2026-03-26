# BioStatAnki <img src="man/figures/logo.png" align="right" height="115"/>

**BioStatAnki** is an R package that turns a set of flash cards into an interactive Shiny quiz for learning biostatistics through live coding.
For every card you write a short R expression, run it, and immediately see both the object returned and whether it matches the expected answer.

---

## Features

| Category | Details |
|----------|---------|
| **Exercises** | `inst/extdata/questions.csv` ships with a growing question bank covering descriptive statistics, epidemiologic measures, regression, survival analysis, Bayesian inference, causal inference, prediction-model performance, multiple testing, mixed models, propensity score matching, and decision curve analysis.<br>• Object tasks can also validate `vector`, `matrix`, `table`, `list`, and `plot` outputs. |
| **Shared quiz engine** | `evaluate_answer()`, `compare_answer_result()`, `check_answer()`, and `validate_questions()` all reuse the same execution and comparison rules. |
| **Three-panel app layout** | **Testing Area** for hands-on quiz execution and validation.<br>**Learning Area** with concise notes tied to tested concepts.<br>**Sandbox** for mock data generation and reproducible analysis snippets. |
| **Sandbox sheet** | Build mock datasets, run selected analyses, execute custom code, and get script snippets plus required libraries for reproducible workflows. |
| **Knowledge repository** | `inst/extdata/knowledge_repository.csv` stores explainers for R, Biostatistics, and Biostatistical Methods, linked to quiz coverage. |
| **Separated panes** | Shiny UI shows *Result* (object) and *Feedback* (correct / incorrect) in separate boxes. |
| **Random order** | Each session shuffles all cards once; no repeats until every card is seen. |
| **Metadata-aware API** | `load_questions(include_metadata = TRUE)`, `list_question_topics()`, `filter_questions()`, `sample_questions()`, `summarize_question_bank()`, `validate_question_row()`, and `get_question_explanation()` support topic-driven study and authoring flows. |
| **Robust validator** | `validate_questions()` executes every row and reports pass/fail. Runs locally and in CI. |
| **Self-healing CSV tool** | `fix_questions.R` recalculates numeric answers using the same evaluation helpers used by the package and app, then creates a backup of the original CSV. |

---

## Documentation

Full API documentation is built with pkgdown into the local `docs/` directory.

## Installation

**Stable release** (v0.3.0):
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
library(biostatAnki)

# launch the quiz
run_app()
```

## Programmatic API

```r
library(biostatAnki)

# full data frame
qdf <- load_questions()
head(qdf)

# derived topic metadata
qdf_meta <- load_questions(include_metadata = TRUE)
list_question_topics()
filter_questions(topic = "Prediction model performance")
summarize_question_bank()

# single question
get_question(12, include_metadata = TRUE, include_explanation = TRUE)

# answer checker
check_answer("median(c(5, 1, 9))", "5")   # TRUE
check_answer("1:10", "vector")             # TRUE (keyword)
compare_answer_result(data.frame(a = 1:3), "table")  # TRUE

# evaluate without immediately checking
evaluate_answer("mean(c(1, 2, 3))")

# validate one draft question row before adding it to the CSV
validate_question_row(list(
  id = 999,
  question = "Compute 1 + 1",
  code = "1 + 1",
  expected_output = "2"
))

# full validation (used in CI / pre-commit)
validate_questions()                       # All questions passed
```

## Development

### Setup

```r
# Use renv for an interactive reproducible development environment
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

- ChatGPT/Codex loop: `./biostatanki_autonomous_loop.ps1`
- Claude loop (sidecar): `./autonomous_loop_claude.ps1`

Shared logic:

- Prompt template: `claude_cycle_prompt.txt`
- Daily external fetch: `daily_external_fetch.js`
- ChatGPT cycle runner: `run_cycle.js`
- Claude cycle runner: `run_cycle_claude.js`

Important: run only one autonomous loop at a time to avoid concurrent edits.

### Reproducible environment

The `renv.lock` file captures all package versions. Interactive sessions
activate `renv` automatically; for non-interactive scripts you can opt in with
`BIOSTATANKI_ACTIVATE_RENV=true`.

Contributors can restore the environment with:
```r
renv::restore()
```

## Shiny app

This Shiny app is built from:

- **UI** — topic filter, text area for code, action buttons, progress, and explanation pane.
- **Server** — runs code through the shared package evaluator, stores the result, and validates it against `expected_output` using the same comparison engine used by tests and dev tools.
- **Reactive programming** keeps the interface in sync with user actions.

## License

MIT © 2025 Jorge Alcántara
