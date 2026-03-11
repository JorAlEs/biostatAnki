# Contributing to biostatAnki

Thank you for your interest in contributing! This guide covers everything you need to get started.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Setting up the development environment](#setting-up-the-development-environment)
3. [Running tests](#running-tests)
4. [Making changes](#making-changes)
5. [Adding or editing questions](#adding-or-editing-questions)
6. [Code style](#code-style)
7. [Submitting a pull request](#submitting-a-pull-request)
8. [Reporting bugs](#reporting-bugs)

---

## Code of Conduct

Please be respectful and constructive in all interactions. We follow the
[Contributor Covenant](https://www.contributor-covenant.org/) code of conduct.

---

## Setting up the development environment

You need **R >= 3.6.0** and the [renv](https://rstudio.github.io/renv/) package.

```r
# 1. Clone the repository
#    git clone https://github.com/jalcantara-espinosa/biostatAnki.git
#    cd biostatAnki

# 2. Restore the locked package environment
renv::restore()

# 3. Load the package in development mode
devtools::load_all()
```

> **Tip:** If you use RStudio, open `biostatAnki.Rproj` and renv will activate
> automatically.

---

## Running tests

The test suite lives in `tests/testthat/` and uses
[testthat](https://testthat.r-lib.org/) edition 3.

```r
# Run all tests
devtools::test()

# Run R CMD check (includes tests + documentation checks)
devtools::check()

# Run a single test file interactively
testthat::test_file("tests/testthat/test-questions.R")
```

All 52 tests must pass before opening a pull request.

---

## Making changes

### Package functions (`R/`)

Each exported function must have complete **roxygen2** documentation
(`@title`, `@param`, `@return`, `@export`, `@examples`). After editing
any `.R` file, regenerate the documentation:

```r
devtools::document()
```

Verify that `NAMESPACE` and the corresponding `.Rd` files in `man/` are
updated correctly.

### Shiny app (`inst/app/app.R`)

The Shiny UI and server logic live in a single file. Keep reactive
expressions focused and avoid side effects outside `reactive()` /
`observeEvent()` blocks.

### Internal helpers

Unexported helpers are prefixed with a dot (e.g., `.quiz_eval_parent()`).
They do **not** need `@export` but should still have a brief roxygen block
for discoverability inside the package.

---

## Adding or editing questions

Questions live in `inst/extdata/questions.csv` with four columns:

| Column | Description |
|--------|-------------|
| `id` | Integer, unique, sequential |
| `question` | Plain-English question text |
| `code` | Valid R expression that produces the answer |
| `expected_output` | Character representation of the evaluated result |

**To add questions:**

1. Append rows to `questions.csv` (keep `id` sequential).
2. Run `fix_questions.R` to recalculate `expected_output` values and
   apply object-type keywords (`vector`, `matrix`):

```r
# Requires: dplyr, here, readr (install if needed)
source("fix_questions.R")
```

3. Confirm that `validate_questions()` still passes:

```r
validate_questions()
```

4. Run the full test suite to make sure nothing regressed:

```r
devtools::test()
```

---

## Code style

- Follow the [tidyverse style guide](https://style.tidyverse.org/).
- Use `snake_case` for function and variable names.
- Keep lines under **100 characters**.
- Avoid non-ASCII characters in source files — use `\uXXXX` escapes.
- No `library()` or `require()` calls inside package source (`R/`);
  use fully qualified calls (`pkg::fn()`) or declare in `DESCRIPTION`.

---

## Submitting a pull request

1. **Fork** the repository and create a branch from `main`:
   ```bash
   git checkout -b feature/my-improvement
   ```
2. Make your changes with focused commits (one logical change per commit).
3. Ensure `devtools::check()` exits with 0 errors and 0 warnings.
4. Push to your fork and open a PR against `main`.
5. Describe *what* changed and *why* in the PR description.

The CI pipeline (GitHub Actions) will automatically run `R CMD check` on
your PR. It must pass before the PR can be merged.

---

## Reporting bugs

Open an issue on GitHub and include:

- R version (`R.version.string`)
- biostatAnki version (`packageVersion("biostatAnki")`)
- A minimal reproducible example (the question `id`, your code, and the
  error or unexpected output)
- The full error message or traceback if applicable
