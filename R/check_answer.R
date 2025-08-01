##' Evaluate a User's Answer
##'
##' This function evaluates a user-provided R expression in a clean
##' environment and compares the resulting value to an expected
##' output.  It returns `TRUE` when the evaluated result matches
##' the expected value (within a small numeric tolerance) and
##' `FALSE` otherwise.  Errors generated during evaluation are
##' treated as incorrect answers.
##'
##' @param user_code A character string containing R code to evaluate.
##' @param expected The expected result.  Typically numeric but may
##'   also be a character or logical value.
##' @return A logical indicating whether the answer is correct.
##' @examples
##' check_answer("mean(c(1,2,3))", 2)  # TRUE
##' check_answer("mean(c(1,2,3))", 3)  # FALSE
##' @export
check_answer <- function(user_code, expected) {
  # Evaluate code safely in a new environment to avoid interfering
  # with global state
  env <- new.env(parent = baseenv())
  result <- try(eval(parse(text = user_code), envir = env), silent = TRUE)
  if (inherits(result, "try-error")) {
    return(FALSE)
  }
  # Convert both values to numeric if possible
  if (is.numeric(expected) && is.numeric(result)) {
    return(isTRUE(all.equal(as.numeric(result), as.numeric(expected), tolerance = 1e-06)))
  }
  # Fallback to strict comparison
  return(identical(result, expected))
}