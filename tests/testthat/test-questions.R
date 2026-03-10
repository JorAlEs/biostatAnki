test_that("all questions are valid", {
  qdf <- validate_questions()
  expect_true(all(qdf$valid))
})

# --- load_questions -----------------------------------------------------------

test_that("load_questions returns a data.frame with required columns", {
  qdf <- load_questions()
  expect_s3_class(qdf, "data.frame")
  expect_true(all(c("id", "question", "code", "expected_output") %in% names(qdf)))
})

test_that("load_questions returns 60 rows", {
  qdf <- load_questions()
  expect_equal(nrow(qdf), 60L)
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
