test_that(".load_package_csv prefers source checkout data when available", {
  temp_root <- tempfile("biostatanki-extdata-")
  nested_dir <- file.path(temp_root, "tests", "nested")

  dir.create(file.path(temp_root, "inst", "extdata"), recursive = TRUE)
  dir.create(nested_dir, recursive = TRUE)

  writeLines(
    c("Package: biostatAnki", "Version: 0.0.0"),
    file.path(temp_root, "DESCRIPTION")
  )
  writeLines(
    c(
      "id,question,code,expected_output",
      "\"999\",\"Local source question\",\"1 + 1\",\"2\""
    ),
    file.path(temp_root, "inst", "extdata", "questions.csv")
  )

  old_wd <- setwd(nested_dir)
  on.exit(setwd(old_wd), add = TRUE)

  qdf <- biostatAnki:::.load_package_csv("questions.csv")

  expect_equal(as.integer(qdf$id[[1]]), 999L)
  expect_equal(qdf$question[[1]], "Local source question")
})
