#' Validate all quiz questions
#'
#' Evaluates every code snippet in `questions_df`
#' and checks it against `expected_output` via the same
#' comparison logic used in the app.
#' Returns an invisible data.frame summarising failures.
#' @export
validate_questions <- function(
  questions_df = biostatAnki::load_questions(),
  tolerance = 1e-6
) {
  compare <- function(result, expected, tol = 1e-6) {

    # --- keyword checks -------------------------------------------
    if (expected == "vector")
      return(is.atomic(result) && is.null(dim(result)))   # any atomic vector
    if (expected == "matrix")
      return(is.matrix(result))

    # --- numeric with tolerance -----------------------------------
    exp_num <- suppressWarnings(as.numeric(expected))
    if (!is.na(exp_num) && is.numeric(result))
      return(isTRUE(all.equal(as.numeric(result), exp_num, tolerance = tol)))

    # --- exact character match ------------------------------------
    if (is.character(expected) && is.character(result))
      return(identical(trimws(result), trimws(expected)))

    # --- fallback --------------------------------------------------
    identical(result, expected)
  }
    if (!is.data.frame(questions_df) || !all(c("id", "question", "code", "expected_output") %in% names(questions_df))) {
        stop("Invalid questions_df format. Must contain 'id', 'question', 'code', and 'expected_output' columns.")
  }

  check_row <- function(code, expected) {
    env <- new.env(parent = globalenv())
    res <- try(eval(parse(text = code), envir = env), silent = TRUE)
    if (inherits(res, "try-error"))
      return(list(ok = FALSE, msg = conditionMessage(attr(res, "condition"))))
    if (!compare(res, expected))
      return(list(ok = FALSE, msg = paste("got:", toString(res))))
    list(ok = TRUE, msg = "")
  }

  # ---- fixed pmap ----
  res_list <- purrr::pmap(
    list(
      code     = questions_df$code,
      expected = questions_df$expected_output     # <- renamed
    ),
    check_row
  )

  questions_df$valid  <- vapply(res_list, `[[`, logical(1), "ok")
  questions_df$detail <- vapply(res_list, `[[`, character(1), "msg")

  bad <- questions_df[!questions_df$valid, c("id", "question", "detail")]
  if (nrow(bad)) {
    message("❌  Found ", nrow(bad), " invalid question(s)")
    print(bad, row.names = FALSE)
  } else {
    message("✅  All questions passed")
  }
  invisible(questions_df)
}
