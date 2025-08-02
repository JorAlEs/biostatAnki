#' Retrieve a Single Question
#'
#' Given a question ID, this helper returns a list containing the
#' question text, the canonical code that solves it, and the
#' expected output.  It is primarily used internally by the
#' Shiny application but may also be useful for programmatic access.
#'
#' @param id An integer corresponding to the desired question ID.
#' @return A list with elements `question`, `code`, and `expected_output`.
#' @export
get_question <- function(id) {
  questions <- load_questions()
  if (!id %in% questions$id) {
    stop("Invalid question id.")
  }
  row <- questions[questions$id == id, , drop = FALSE]
  return(list(
    question = row$question,
    code = row$code,
    expected_output = row$expected_output
  ))
}