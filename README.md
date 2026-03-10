# BioStatAnki <img src="man/figures/logo.png" align="right" height="115"/>

**BioStatAnki** is an R package that turns a set of flash cards into an interactive Shiny quiz for learning biostatistics through live coding.
For every card you write a short R expression, run it, and immediately see both the object returned and whether it matches the expected answer.

---

## Features

| Category | Details |
|----------|---------|
| **Exercises** | `inst/extdata/questions.csv` ships with **60 questions**.<br>• 40 numeric tasks (mean, median, variance, SD, correlation, linear-model slope).<br>• 20 object tasks returning vectors or matrices—tagged with the keywords `vector` or `matrix`. |
| **Two-step workflow** | **Run code** executes the user expression in a safe environment and prints the result.<br>**Check answer** validates that result against the CSV, using numeric tolerance and keyword logic. |
| **Separated panes** | Shiny UI shows *Result* (object) and *Feedback* (correct / incorrect) in separate boxes. |
| **Random order** | Each session shuffles all cards once; no repeats until every card is seen. |
| **Robust validator** | `validate_questions()` executes every row and reports pass/fail. Runs locally and in CI. |
| **Self-healing CSV tool** | `fix_questions.R` recalculates numeric answers, tags objects with keywords, and creates a backup of the original CSV. |

---

## Installation

```r
# from a local clone
devtools::install_local("path/to/BioStatAnki")

# or directly from GitHub
remotes::install_github("JorAlEs/BioStatAnki")
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

## Development utilities

| Script / tool                      | Purpose                                                                                                                       |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **`fix_questions.R`**              | Evaluates every `code`, writes full-precision numeric answers, tags object outputs (`vector`, `matrix`) and backs up the CSV. |
| **Git pre-commit hook** (optional) | Runs `validate_questions()` and blocks commits that break the question set.                                                   |

## Shiny app

This Shiny app is built from:

- **UI** — text area for code, action buttons, two output panes.
- **Server** — runs the code in a clean environment, stores the result, and validates it against `expected_output` using numeric tolerance and keyword recognition.
- **Reactive programming** keeps the interface in sync with user actions.

## License

MIT © 2025 Jorge Alcántara
