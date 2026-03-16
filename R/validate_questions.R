#' Validate all Quiz Questions
#'
#' Evaluates every canonical code snippet in `questions_df` and checks it
#' against `expected_output` via the same shared comparison logic used by the
#' app and package helpers.
#'
#' @param questions_df A `data.frame` with columns `id`, `question`, `code`, and
#'   `expected_output`. Defaults to `load_questions()`.
#' @param tolerance Numeric tolerance used when comparing numeric results.
#' @return Invisibly returns `questions_df` augmented with `valid` and `detail`
#'   columns.
#' @examples
#' validation <- validate_questions()
#' all(validation$valid)
#' @export
validate_questions <- function(questions_df = biostatAnki::load_questions(),
                               tolerance = 1e-6) {
  required_columns <- c("id", "question", "code", "expected_output")

  if (!is.data.frame(questions_df) || !all(required_columns %in% names(questions_df))) {
    stop(
      "Invalid questions_df format. Must contain 'id', 'question', 'code', and 'expected_output' columns."
    )
  }

  res_list <- lapply(seq_len(nrow(questions_df)), function(i) {
    evaluation <- evaluate_answer(
      user_code = questions_df$code[[i]],
      tolerance = tolerance
    )

    if (!evaluation$ok) {
      return(list(ok = FALSE, msg = evaluation$error))
    }

    if (!compare_answer_result(
      result = evaluation$result,
      expected_output = questions_df$expected_output[[i]],
      tolerance = tolerance
    )) {
      return(list(ok = FALSE, msg = paste("got:", toString(evaluation$result))))
    }

    list(ok = TRUE, msg = "")
  })

  questions_df$valid <- vapply(res_list, `[[`, logical(1), "ok")
  questions_df$detail <- vapply(res_list, `[[`, character(1), "msg")

  bad <- questions_df[!questions_df$valid, c("id", "question", "detail")]
  if (nrow(bad)) {
    message("\u274c  Found ", nrow(bad), " invalid question(s)")
    print(bad, row.names = FALSE)
  } else {
    message("\u2705  All questions passed")
  }

  invisible(questions_df)
}
