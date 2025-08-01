##' Load Quiz Questions
##'
##' Reads the CSV file containing the bio-statistics questions bundled
##' with the package into a data frame.  The file is stored under
##' `inst/extdata/questions.csv` in the source repository and is
##' installed into the package when built.  Each row in the returned
##' data frame represents a single question with the following
##' columns:
##'
##' * `id` -- integer identifier.
##' * `question` -- the text of the question presented to the user.
##' * `code` -- a canonical R expression that computes the answer.
##' * `expected_output` -- the numeric answer expected when the code
##'   is executed.
##'
##' @return A `data.frame` containing all quiz questions.
##' @export
load_questions <- function() {
  csv_path <- system.file("extdata", "questions.csv", package = "bioStatAnki")
  if (csv_path == "") {
    stop("Questions file not found in package resources.")
  }
  questions <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
  return(questions)
}