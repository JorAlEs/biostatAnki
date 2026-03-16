#' Retrieve a Single Question
#'
#' Given a question ID, returns a named list containing the question text, the
#' canonical code that solves it, and the expected output. Metadata and the
#' paired explanation can also be included on demand.
#'
#' @param id An integer corresponding to the desired question ID.
#' @param include_metadata Logical. If `TRUE`, include derived metadata fields.
#' @param include_explanation Logical. If `TRUE`, include the paired topic note
#'   from the knowledge repository.
#' @return A named list describing a single question.
#' @examples
#' q <- get_question(1)
#' cat(q$question)
#'
#' q_meta <- get_question(100, include_metadata = TRUE, include_explanation = TRUE)
#' q_meta$topic
#' @export
get_question <- function(id,
                         include_metadata = FALSE,
                         include_explanation = FALSE) {
  questions <- load_questions(include_metadata = include_metadata)
  if (!id %in% questions$id) {
    stop("Invalid question id.")
  }

  row <- questions[questions$id == id, , drop = FALSE]
  question <- list(
    id = row$id[[1]],
    question = row$question[[1]],
    code = row$code[[1]],
    expected_output = row$expected_output[[1]]
  )

  if (include_metadata) {
    question$section <- row$section[[1]]
    question$topic <- row$topic[[1]]
    question$difficulty <- row$difficulty[[1]]
    question$tags <- row$tags[[1]]
  }

  if (include_explanation) {
    question$explanation <- get_question_explanation(id = id, questions_df = questions)
  }

  question
}
