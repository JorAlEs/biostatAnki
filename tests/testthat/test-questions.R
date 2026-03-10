test_that("all questions are valid", {
  qdf <- validate_questions()
  expect_true(all(qdf$valid))
})
