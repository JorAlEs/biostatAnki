#' Load Quiz Questions
#'
#' Reads the packaged question bank into a data frame. By default the function
#' returns the four persisted columns stored in `inst/extdata/questions.csv`.
#' When `include_metadata = TRUE`, the returned data frame is augmented with
#' derived `section`, `topic`, `difficulty`, and `tags` columns.
#'
#' @param include_metadata Logical. If `TRUE`, append derived metadata columns.
#' @return A `data.frame` containing all quiz questions.
#' @examples
#' questions <- load_questions()
#' head(questions)
#'
#' questions_with_meta <- load_questions(include_metadata = TRUE)
#' names(questions_with_meta)
#' @export
load_questions <- function(include_metadata = FALSE) {
  questions <- .load_package_csv("questions.csv")
  questions$id <- as.integer(questions$id)

  if (!include_metadata) {
    return(questions)
  }

  .augment_question_metadata(questions)
}
