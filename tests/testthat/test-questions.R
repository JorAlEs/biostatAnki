test_that("all questions are valid", {
  qdf <- validate_questions()
  expect_true(all(qdf$valid))
})

# --- run_app ------------------------------------------------------------------

test_that("run_app delegates to shiny::runApp with resolved defaults", {
  captured <- list()

  result <- with_mocked_bindings(
    with_mocked_bindings(
      run_app(
        host = "127.0.0.1",
        port = NULL,
        launch.browser = FALSE,
        quiet = TRUE,
        test_flag = "x"
      ),
      runApp = function(appDir, host, port, launch.browser, ...) {
        captured$appDir <<- appDir
        captured$host <<- host
        captured$port <<- port
        captured$launch.browser <<- launch.browser
        captured$dots <<- list(...)
        "ok"
      },
      .package = "shiny"
    ),
    randomPort = function() 4321L,
    .package = "httpuv"
  )

  expect_equal(result, "ok")
  expect_true(nzchar(captured$appDir))
  expect_equal(captured$host, "127.0.0.1")
  expect_equal(captured$port, 4321L)
  expect_false(captured$launch.browser)
  expect_equal(captured$dots$test_flag, "x")
})

test_that("run_app returns runApp result invisibly", {
  result <- with_mocked_bindings(
    withVisible(run_app(port = 1234L, launch.browser = FALSE, quiet = TRUE)),
    runApp = function(...) "ok",
    .package = "shiny"
  )

  expect_equal(result$value, "ok")
  expect_false(result$visible)
})

test_that("run_app errors when shiny is unavailable", {
  expect_error(
    with_mocked_bindings(
      run_app(quiet = TRUE),
      .has_namespace = function(...) FALSE,
      .package = "biostatAnki"
    ),
    "Package 'shiny' is required but not installed.",
    fixed = TRUE
  )
})

test_that("run_app errors when packaged app directory is missing", {
  expect_error(
    with_mocked_bindings(
      run_app(quiet = TRUE),
      .has_namespace = function(...) TRUE,
      .get_app_dir = function(...) "",
      .package = "biostatAnki"
    ),
    "Cannot find Shiny app directory. Try reinstalling 'biostatAnki'.",
    fixed = TRUE
  )
})

# --- load_questions -----------------------------------------------------------

test_that("load_questions returns a data.frame with required columns", {
  qdf <- load_questions()
  expect_s3_class(qdf, "data.frame")
  expect_true(all(c("id", "question", "code", "expected_output") %in% names(qdf)))
})

test_that("load_questions has non-empty, unique, contiguous ids", {
  qdf <- load_questions()
  expect_gt(nrow(qdf), 0L)
  expect_equal(length(unique(qdf$id)), nrow(qdf))
  expect_equal(sort(as.integer(qdf$id)), seq_len(nrow(qdf)))
})

# --- check_answer -------------------------------------------------------------

test_that("check_answer returns TRUE for correct numeric answer", {
  expect_true(check_answer("mean(c(1, 2, 3))", "2"))
})

test_that("check_answer returns FALSE for wrong numeric answer", {
  expect_false(check_answer("mean(c(1, 2, 3))", "3"))
})

test_that("check_answer uses numeric tolerance", {
  # mean of 1:3 is exactly 2; check that small deviation still matches
  expect_true(check_answer("mean(c(1, 2, 3))", "2.0000001"))
  expect_false(check_answer("mean(c(1, 2, 3))", "2.1"))
})

test_that("check_answer can use stats functions without global leakage", {
  expect_true(check_answer("median(c(1, 2, 3))", "2"))
})

test_that(".quiz_eval_parent falls back to stats namespace when stats is detached", {
  if (!("package:stats" %in% search())) {
    skip("package:stats is not attached in this session")
  }

  on.exit({
    if (!("package:stats" %in% search())) {
      library(stats)
    }
  }, add = TRUE)

  detached <- tryCatch({
    suppressWarnings(detach("package:stats", character.only = TRUE))
    TRUE
  }, error = function(...) FALSE)

  if (!detached || "package:stats" %in% search()) {
    skip("Could not detach package:stats in this session")
  }

  expect_identical(biostatAnki:::.quiz_eval_parent(), asNamespace("stats"))
})

test_that("check_answer returns FALSE for syntax errors", {
  expect_false(check_answer("mean(c(1,", "1"))
})

test_that("check_answer returns FALSE for runtime errors", {
  expect_false(check_answer("log('not_a_number')", "1"))
})

test_that("check_answer matches character output exactly (trimmed)", {
  expect_true(check_answer("'hello'", "hello"))
  expect_false(check_answer("'hello'", "world"))
})

test_that("check_answer handles 'vector' keyword correctly", {
  expect_true(check_answer("c(1, 2, 3)", "vector"))
  expect_true(check_answer("1:5", "vector"))
  expect_false(check_answer("matrix(1:4, 2, 2)", "vector"))
})

test_that("check_answer handles 'matrix' keyword correctly", {
  expect_true(check_answer("matrix(1:4, 2, 2)", "matrix"))
  expect_false(check_answer("c(1, 2, 3)", "matrix"))
})

test_that("check_answer supports expression-style expected outputs", {
  expect_true(check_answer("c(TRUE, FALSE)", "c(TRUE, FALSE)"))
  expect_false(check_answer("c(TRUE, FALSE)", "c(TRUE, TRUE)"))

  expect_true(check_answer("c('apple', 'banana')", "c('apple', 'banana')"))
  expect_false(check_answer("c('apple', 'banana')", "c('apple', 'orange')"))

  expect_true(check_answer("c(1, 2, 3)", "c(1, 2, 3)"))
  expect_false(check_answer("c(1, 2, 3)", "c(1, 2, 4)"))
})

test_that("check_answer returns FALSE for missing expected output", {
  expect_false(check_answer("NA", NA_character_))
})

test_that("check_answer handles Inf and -Inf correctly", {
  expect_true(check_answer("1/0", "Inf"))
  expect_true(check_answer("-1/0", "-Inf"))
  expect_false(check_answer("1/0", "0"))
  expect_false(check_answer("1/0", "-Inf"))
})

test_that("check_answer handles NaN correctly", {
  expect_true(check_answer("0/0", "NaN"))
  expect_false(check_answer("0/0", "0"))
})

test_that("validate_questions marks missing expected output as invalid", {
  bad_expected_df <- data.frame(
    id = 1L,
    question = "Missing expected output",
    code = "NA",
    expected_output = NA_character_,
    stringsAsFactors = FALSE
  )

  result <- validate_questions(questions_df = bad_expected_df)
  expect_false(result$valid[1])
  expect_match(result$detail[1], "^got:")
})

test_that(".compare_expected_output handles logical and list fallbacks", {
  expect_true(biostatAnki:::.compare_expected_output(c(TRUE, FALSE), c(TRUE, FALSE)))
  expect_false(biostatAnki:::.compare_expected_output(c(TRUE, FALSE), c(TRUE, TRUE)))

  expect_true(
    biostatAnki:::.compare_expected_output(
      list(alpha = 1L, beta = "x"),
      list(alpha = 1L, beta = "x")
    )
  )
  expect_false(
    biostatAnki:::.compare_expected_output(
      list(alpha = 1L, beta = "x"),
      list(alpha = 2L, beta = "x")
    )
  )
})

# --- get_question -------------------------------------------------------------

test_that("get_question returns a list with expected elements", {
  q <- get_question(1)
  expect_type(q, "list")
  expect_true(all(c("question", "code", "expected_output") %in% names(q)))
})

test_that("get_question stops on invalid id", {
  expect_error(get_question(9999), "Invalid question id")
})

# --- validate_questions -------------------------------------------------------

test_that("validate_questions errors on non-data.frame input", {
  expect_error(validate_questions(questions_df = "not a data frame"), "Invalid questions_df format")
})

test_that("validate_questions errors on data.frame with missing columns", {
  bad_df <- data.frame(id = 1, question = "q")
  expect_error(validate_questions(questions_df = bad_df), "Invalid questions_df format")
})

test_that("validate_questions returns correct result for a single good row", {
  good_df <- data.frame(
    id = 1L,
    question = "What is 1 + 1?",
    code = "1 + 1",
    expected_output = "2",
    stringsAsFactors = FALSE
  )
  result <- validate_questions(questions_df = good_df)
  expect_true(result$valid[1])
})

test_that("validate_questions marks a bad row as invalid", {
  bad_df <- data.frame(
    id = 1L,
    question = "Intentionally wrong",
    code = "1 + 1",
    expected_output = "999",
    stringsAsFactors = FALSE
  )
  result <- validate_questions(questions_df = bad_df)
  expect_false(result$valid[1])
})

test_that("validate_questions honors tolerance argument", {
  tol_df <- data.frame(
    id = 1L,
    question = "Tolerance behavior",
    code = "2 + 1e-05",
    expected_output = "2",
    stringsAsFactors = FALSE
  )

  strict <- validate_questions(questions_df = tol_df, tolerance = 1e-6)
  loose <- validate_questions(questions_df = tol_df, tolerance = 1e-4)

  expect_false(strict$valid[1])
  expect_true(loose$valid[1])
})

test_that("validate_questions does not use global variables", {
  marker <- ".__biostatanki_global_probe__"
  assign(marker, 2, envir = .GlobalEnv)
  on.exit(rm(list = marker, envir = .GlobalEnv), add = TRUE)

  probe_df <- data.frame(
    id = 1L,
    question = "Global state leakage probe",
    code = marker,
    expected_output = "2",
    stringsAsFactors = FALSE
  )

  result <- validate_questions(questions_df = probe_df)
  expect_false(result$valid[1])
})
