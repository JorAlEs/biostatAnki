#' Shared Quiz Evaluation Helpers
#'
#' Internal helpers used across the package to evaluate user code and compare
#' results with stored expected outputs.
#' @keywords internal
#' @noRd
.quiz_eval_parent <- function() {
  if ("package:stats" %in% search()) {
    return(as.environment("package:stats"))
  }

  asNamespace("stats")
}

.quiz_evaluate_code <- function(user_code, bindings = NULL, env_parent = .quiz_eval_parent()) {
  env <- new.env(parent = env_parent)

  if (!is.null(bindings)) {
    list2env(bindings, envir = env)
  }

  result <- try(eval(parse(text = user_code), envir = env), silent = TRUE)

  if (inherits(result, "try-error")) {
    return(list(
      ok = FALSE,
      result = NULL,
      error = conditionMessage(attr(result, "condition"))
    ))
  }

  list(
    ok = TRUE,
    result = result,
    error = NULL
  )
}

.classify_object_result <- function(result) {
  if (is.matrix(result)) {
    return("matrix")
  }

  if (inherits(result, "table") || is.data.frame(result)) {
    return("table")
  }

  if (inherits(result, "gg") || inherits(result, "ggplot")) {
    return("plot")
  }

  if (is.list(result) && !is.data.frame(result)) {
    return("list")
  }

  if (is.atomic(result) && is.null(dim(result))) {
    return("vector")
  }

  "unknown"
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
  eval_env$data.frame <- base::data.frame
  eval_env$factor <- base::factor
  eval_env$`:` <- base::`:`

  evaluated <- try(eval(parsed[[1]], envir = eval_env), silent = TRUE)
  if (inherits(evaluated, "try-error")) {
    return(NULL)
  }

  evaluated
}

#' Compare an Evaluated Result with the Expected Output
#'
#' Matches an already evaluated R object against the expected output used by the
#' quiz bank. Numeric values use a tolerance; object keywords such as
#' `vector`, `matrix`, `table`, `list`, and `plot` are also supported.
#'
#' @param result An evaluated R object.
#' @param expected_output Expected result as a character string (from the quiz
#'   CSV), or an R object for direct comparison.
#' @param tolerance Numeric tolerance used when comparing numeric values.
#' @return `TRUE` when the result matches the expectation, otherwise `FALSE`.
#' @examples
#' compare_answer_result(2, "2")
#' compare_answer_result(c(1, 2, 3), "vector")
#' compare_answer_result(matrix(1:4, 2, 2), "matrix")
#' @export
compare_answer_result <- function(result, expected_output, tolerance = 1e-6) {
  .compare_expected_output(
    result = result,
    expected_output = expected_output,
    tolerance = tolerance
  )
}

#' Evaluate a User Expression
#'
#' Evaluates R code in a clean quiz environment and optionally compares the
#' result against an expected output.
#'
#' @param user_code A string containing the R code to evaluate.
#' @param expected_output Optional expected result. When supplied, the returned
#'   list includes `matches_expected`.
#' @param tolerance Numeric tolerance used when comparing numeric values.
#' @param bindings Optional named list of objects to preload into the evaluation
#'   environment. This is mainly useful for app or sandbox workflows.
#' @return A list with `ok`, `result`, `error`, and `matches_expected`.
#' @examples
#' evaluation <- evaluate_answer("mean(c(1, 2, 3))", "2")
#' evaluation$ok
#' evaluation$matches_expected
#' @export
evaluate_answer <- function(user_code,
                            expected_output,
                            tolerance = 1e-6,
                            bindings = NULL) {
  evaluation <- .quiz_evaluate_code(
    user_code = user_code,
    bindings = bindings
  )

  if (!missing(expected_output)) {
    evaluation$matches_expected <- evaluation$ok &&
      compare_answer_result(
        result = evaluation$result,
        expected_output = expected_output,
        tolerance = tolerance
      )
  } else {
    evaluation$matches_expected <- NULL
  }

  evaluation
}

#' Evaluate a User's Answer
#'
#' Evaluates R code in a clean environment and compares the result to the
#' expected output as defined in the quiz dataset.
#'
#' @param user_code A string containing the R code submitted by the user.
#' @param expected_output Expected result as a character string (from the quiz
#'   CSV), or an R object for direct comparison.
#' @param tolerance Numeric tolerance used when comparing numeric values.
#' @return `TRUE` if the result matches the expected output; `FALSE` otherwise.
#' @examples
#' check_answer("mean(c(1, 2, 3))", "2")       # TRUE
#' check_answer("mean(c(1, 2, 3))", "3")       # FALSE
#' check_answer("c(1, 2, 3)", "c(1, 2, 3)")    # TRUE
#' check_answer("c(1, 2, 3)", "c(1, 2, 4)")    # FALSE
#' @export
check_answer <- function(user_code, expected_output, tolerance = 1e-6) {
  evaluation <- evaluate_answer(
    user_code = user_code,
    expected_output = expected_output,
    tolerance = tolerance
  )

  isTRUE(evaluation$matches_expected)
}

.compare_expected_output <- function(result, expected_output, tolerance = 1e-6) {
  if (length(expected_output) == 1L && is.atomic(expected_output) && is.na(expected_output)) {
    return(FALSE)
  }

  if (is.character(expected_output) && length(expected_output) == 1L) {
    expected_chr <- expected_output[[1]]

    if (!is.na(expected_chr)) {
      if (expected_chr == "vector") {
        return(is.atomic(result) && is.null(dim(result)))
      }

      if (expected_chr == "matrix") {
        return(is.matrix(result))
      }

      if (expected_chr == "table") {
        return(inherits(result, "table") || is.data.frame(result))
      }

      if (expected_chr == "list") {
        return(is.list(result) && !is.data.frame(result))
      }

      if (expected_chr == "plot") {
        return(inherits(result, "gg") || inherits(result, "ggplot"))
      }

      expected_num <- suppressWarnings(as.numeric(expected_chr))
      if (!is.na(expected_num) && is.numeric(result)) {
        return(isTRUE(all.equal(as.numeric(result), expected_num, tolerance = tolerance)))
      }

      if (is.character(result) && length(result) == 1L &&
          identical(trimws(result), trimws(expected_chr))) {
        return(TRUE)
      }

      expected_evaluated <- .safe_eval_expected_output(expected_chr)
      if (!is.null(expected_evaluated)) {
        if (is.numeric(result) && is.numeric(expected_evaluated)) {
          return(isTRUE(all.equal(result, expected_evaluated, tolerance = tolerance)))
        }

        return(identical(result, expected_evaluated))
      }
    }
  }

  identical(result, expected_output)
}
