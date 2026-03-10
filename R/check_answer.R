#' Evaluate a User's Answer (Simple Equality Check)
#'
#' This function evaluates R code in a clean environment and compares the result
#' to the expected_output as defined in the quiz dataset.
#'
#' @param user_code A string with the R code input from the user.
#' @param expected_output Expected result as character (from the quiz CSV).
#' @return TRUE if the result matches the expected output; FALSE otherwise.
#' @export
.quiz_eval_parent <- function() {
  if ("package:stats" %in% search()) {
    return(as.environment("package:stats"))
  }
  asNamespace("stats")
}

check_answer <- function(user_code, expected_output) {
  env <- new.env(parent = .quiz_eval_parent())
  result <- try(eval(parse(text = user_code), envir = env), silent = TRUE)

  if (inherits(result, "try-error")) return(FALSE)

  .compare_expected_output(result, expected_output, tolerance = 1e-6)
}

.compare_expected_output <- function(result, expected_output, tolerance = 1e-6) {
  if (length(expected_output) == 1L && is.atomic(expected_output) && is.na(expected_output)) {
    return(FALSE)
  }

  if (is.character(expected_output) && length(expected_output) == 1L) {
    expected_chr <- expected_output[[1]]

    if (!is.na(expected_chr)) {
      # Keyword checks (must come before numeric coercion)
      if (expected_chr == "vector") return(is.atomic(result) && is.null(dim(result)))
      if (expected_chr == "matrix") return(is.matrix(result))

      # Try to convert expected_output to numeric
      expected_num <- suppressWarnings(as.numeric(expected_chr))

      # Numeric match (with tolerance)
      if (!is.na(expected_num) && is.numeric(result)) {
        return(isTRUE(all.equal(as.numeric(result), expected_num, tolerance = tolerance)))
      }

      # Character match
      if (is.character(result)) {
        return(identical(trimws(result), trimws(expected_chr)))
      }
    }
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
