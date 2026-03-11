.quiz_eval_parent <- function() {
  if ("package:stats" %in% search()) {
    return(as.environment("package:stats"))
  }
  asNamespace("stats")
}

#' Evaluate a User's Answer
#'
#' Evaluates R code in a clean environment and compares the result to the
#' expected output as defined in the quiz dataset.
#'
#' @param user_code A string containing the R code submitted by the user.
#' @param expected_output Expected result as a character string (from the quiz
#'   CSV), or an R object for direct comparison.
#' @return \code{TRUE} if the result matches the expected output; \code{FALSE}
#'   otherwise.
#' @examples
#' check_answer("mean(c(1, 2, 3))", "2")       # TRUE
#' check_answer("mean(c(1, 2, 3))", "3")       # FALSE
#' check_answer("c(1, 2, 3)", "c(1, 2, 3)")   # TRUE
#' check_answer("c(1, 2, 3)", "c(1, 2, 4)")   # FALSE
#' @export
check_answer <- function(user_code, expected_output) {
  env <- new.env(parent = .quiz_eval_parent())
  result <- try(eval(parse(text = user_code), envir = env), silent = TRUE)

  if (inherits(result, "try-error")) return(FALSE)

  .compare_expected_output(result, expected_output, tolerance = 1e-6)
}

.safe_eval_expected_output <- function(expected_chr) {
  parsed <- try(parse(text = expected_chr), silent = TRUE)
  if (inherits(parsed, "try-error") || length(parsed) != 1L) {
    return(NULL)
  }

  eval_env <- new.env(parent = emptyenv())
  eval_env$c <- base::c
  eval_env$list <- base::list
  eval_env$matrix <- base::matrix
  eval_env$`:` <- base::`:`

  evaluated <- try(eval(parsed[[1]], envir = eval_env), silent = TRUE)
  if (inherits(evaluated, "try-error")) {
    return(NULL)
  }

  evaluated
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
      if (is.character(result) && length(result) == 1L &&
          identical(trimws(result), trimws(expected_chr))) {
        return(TRUE)
      }

      # Expression-style expected output (for vectors/matrices/lists)
      expected_evaluated <- .safe_eval_expected_output(expected_chr)
      if (!is.null(expected_evaluated)) {
        if (is.numeric(result) && is.numeric(expected_evaluated)) {
          return(isTRUE(all.equal(result, expected_evaluated, tolerance = tolerance)))
        }
        return(identical(result, expected_evaluated))
      }
    }
  }

  # Fallback to identical match
  identical(result, expected_output)
}
