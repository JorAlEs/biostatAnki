#!/usr/bin/env Rscript
## Simple test script for the bioStatAnki package
##
## This script performs a few sanity checks to verify that the
## functions included in the package are working as expected.  Run
## it with Rscript from the package root:
##   Rscript test/run_tests.R

library(bioStatAnki)

# 1. Load questions and check count
qs <- load_questions()
if (nrow(qs) != 50) {
  stop(sprintf("Expected 50 questions but found %d", nrow(qs)))
} else {
  message("✔ Loaded 50 questions")
}

# 2. Test get_question
q1 <- get_question(1)
if (!all(c("question", "code", "expected_output") %in% names(q1))) {
  stop("get_question() does not return expected fields")
} else {
  message("✔ get_question() returns expected fields")
}

# 3. Test check_answer: correct and incorrect scenarios
if (!check_answer("mean(c(1,2,3))", 2)) {
  stop("check_answer failed on a correct simple example")
} else {
  message("✔ check_answer() validates correct answer")
}
if (check_answer("mean(c(1,2,3))", 3)) {
  stop("check_answer incorrectly accepted wrong answer")
} else {
  message("✔ check_answer() rejects incorrect answer")
}

message("All tests passed!")