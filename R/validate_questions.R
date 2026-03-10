#' Validate all quiz questions
#'
#' Evaluates every code snippet in `questions_df`
#' and checks it against `expected_output` via the same
#' comparison logic used in the app.
#' Returns an invisible data.frame summarising failures.
#'
#' @param questions_df A data.frame with columns \code{id}, \code{question},
#'   \code{code}, and \code{expected_output}.  Defaults to
#'   \code{biostatAnki::load_questions()}.
#' @param tolerance Numeric tolerance used when comparing numeric results.
#'   Default \code{1e-6}.
#' @export
validate_questions <- function(
  questions_df = biostatAnki::load_questions(),
  tolerance = 1e-6
) {
    if (!is.data.frame(questions_df) || !all(c("id", "question", "code", "expected_output") %in% names(questions_df))) {
        stop("Invalid questions_df format. Must contain 'id', 'question', 'code', and 'expected_output' columns.")
  }

  check_row <- function(code, expected) {
    env <- new.env(parent = .quiz_eval_parent())
    res <- try(eval(parse(text = code), envir = env), silent = TRUE)
    if (inherits(res, "try-error"))
      return(list(ok = FALSE, msg = conditionMessage(attr(res, "condition"))))
    if (!.compare_expected_output(res, expected, tolerance = tolerance))
      return(list(ok = FALSE, msg = paste("got:", toString(res))))
    list(ok = TRUE, msg = "")
  }

  res_list <- Map(check_row, questions_df$code, questions_df$expected_output)

  questions_df$valid  <- vapply(res_list, `[[`, logical(1), "ok")
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
