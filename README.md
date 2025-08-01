BioStatAnki Package
===================

This repository contains an R package called **bioStatAnki**.  The goal of the
package is to provide an interactive learning environment for
bio‑statistics concepts using a set of Anki‑style flashcards delivered
through a Shiny web application.  Each card presents a question that
can be answered by writing a short R expression.  When the user
submits their code, the application evaluates it and compares the
result with the expected answer, providing immediate feedback.

### Key features

* **Fifty exercises:** The package ships with a CSV file in
  `inst/extdata/questions.csv` containing 50 questions covering
  descriptive statistics (mean, median, variance, standard deviation),
  correlation, and simple linear regression.  Each question includes
  example code and the pre‑computed expected result.

* **Interactive Shiny app:** The Shiny app included in
  `inst/app/app.R` presents one question at a time.  Users enter their
  R code into a text area, and pressing **Check answer** evaluates the
  code in a clean environment.  The app compares the user’s result
  against the expected value and reports whether it is correct.  A
  **Next question** button cycles through the exercises.

* **Modular functions:** Functions such as `load_questions()`,
  `get_question()`, and `check_answer()` live in the `R/` directory.
  They make it straightforward to load the dataset, extract a single
  question, and verify user answers programmatically.  The `run_app()`
  function launches the Shiny app from within an installed package.

* **Package‑based structure:** Organising a Shiny app as an R
  package is encouraged for larger or long‑term projects【342098001847609†L46-L56】.  The
  package contains a `DESCRIPTION` file, exports the key functions via
  the `NAMESPACE` file, and stores data under `inst/extdata/`.

### Installation and usage

1. Install the package from the local directory using `devtools`:

   ```r
   # install.packages("devtools")
   devtools::install_local("/path/to/bioStatAnki")
   ```

2. Launch the Shiny quiz with:

   ```r
   library(bioStatAnki)
   run_app()
   ```

   The app will open in your default web browser.  Each card
   describes a task; enter your R code and click **Check answer** to
   verify your response.

3. Programmatically load questions or test the evaluation functions:

   ```r
   library(bioStatAnki)
   q <- load_questions()
   head(q)
   get_question(1)
   check_answer("mean(c(1,2,3))", 2)  # returns TRUE
   ```

### About Shiny

Shiny is an R framework that turns R code into interactive web
applications.  Every Shiny app has a **UI** component that defines
what the user sees and a **server** function that specifies how the
app works.  Reactive programming automatically updates outputs when
inputs change【617308822813800†L48-L53】.  Packaging a Shiny app as an R
package not only organises the code but also unlocks tooling for
testing and documentation【342098001847609†L46-L56】.
