#' Evaluate a User's Answer (Simple Equality Check)
#'
#' This function evaluates R code in a clean environment and compares the result
#' to the expected_output as defined in the quiz dataset.
#'
#' @param user_code A string with the R code input from the user.
#' @param expected_output Expected result as character (from the quiz CSV).
#' @return TRUE if the result matches the expected output; FALSE otherwise.
#' @export
check_answer <- function(user_code, expected_output) {
  env <- new.env(parent = baseenv())
  result <- try(eval(parse(text = user_code), envir = env), silent = TRUE)

  if (inherits(result, "try-error")) return(FALSE)

  # Try to convert expected_output to numeric
  expected_num <- suppressWarnings(as.numeric(expected_output))

  # Numeric match (with tolerance)
  if (!is.na(expected_num) && is.numeric(result)) {
    return(isTRUE(all.equal(as.numeric(result), expected_num, tolerance = 1e-6)))
  }

  # Character match
  if (is.character(expected_output) && is.character(result)) {
    return(identical(trimws(result), trimws(expected_output)))
  }

  # Fallback to identical match
  identical(result, expected_output)
}
#' @examples
#' # Example usage:
#' check_answer("mean(c(1,2,3))", "2")
#' check_answer("mean(c(1,2,3))", "3")
#' check_answer("c('apple', 'banana')", "c('apple', 'banana')")
#' check_answer("c(TRUE, FALSE)", "c(TRUE, FALSE)")
#' check_answer("c(1, 2, 3)", "c(1, 2, 3)")
#' check_answer("c(1, 2, 3)", "c(1, 2, 4)")  # Should return FALSE  