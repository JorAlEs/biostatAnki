.load_package_csv <- function(file_name) {
  csv_path <- system.file("extdata", file_name, package = "biostatAnki")
  if (csv_path == "") {
    csv_path <- file.path("inst", "extdata", file_name)
  }

  if (!file.exists(csv_path)) {
    stop(sprintf("Package resource '%s' not found.", file_name))
  }

  utils::read.csv(csv_path, stringsAsFactors = FALSE)
}

.normalize_question_text <- function(x) {
  tolower(trimws(x))
}

.infer_question_topic <- function(question, code = "") {
  text <- paste(.normalize_question_text(question), .normalize_question_text(code))

  if (grepl("decision curve|net benefit", text)) {
    return(c(section = "Biostatistical Methods", topic = "Decision curve analysis"))
  }

  if (grepl("propensity score", text)) {
    return(c(section = "Biostatistical Methods", topic = "Propensity score matching"))
  }

  if (grepl("bonferroni|benjamini-hochberg|\\bfdr\\b|multiple testing", text)) {
    return(c(section = "Biostatistical Methods", topic = "Multiple testing corrections"))
  }

  if (grepl("intraclass correlation|\\bicc\\b|mixed model|random-intercept", text)) {
    return(c(section = "Biostatistical Methods", topic = "Mixed models and ICC"))
  }

  if (grepl("auc|c-statistic|concordance statistic|concordant pairs|brier score|calibration slope|calibration-in-the-large|\\bcitl\\b|recalibrat", text)) {
    return(c(section = "Biostatistical Methods", topic = "Prediction model performance"))
  }

  if (grepl("bayesian|posterior|prior|credible interval|bayes factor", text)) {
    return(c(section = "Biostatistical Methods", topic = "Bayesian inference"))
  }

  if (grepl("g.computation|marginal standard|mendelian randomization|average treatment effect|\\bate\\b|\\bcate\\b|randomized experiment|missing completely at random|\\bmcar\\b", text)) {
    return(c(section = "Biostatistical Methods", topic = "Causal inference and missing data"))
  }

  if (grepl("kaplan-meier|survival|hazard|person-years|competing risk|fine-gray", text)) {
    return(c(section = "Biostatistical Methods", topic = "Survival and competing risks"))
  }

  if (grepl("logistic regression|linear model|pearson correlation|ridge regression", text)) {
    return(c(section = "Biostatistical Methods", topic = "Regression modeling"))
  }

  if (grepl("cohort study|case-control|diagnostic test|screening test|relative risk|odds ratio|number needed to treat|\\bnnt\\b|attributable risk|specificity|sensitivity|positive predictive value|\\bppv\\b", text)) {
    return(c(section = "Biostatistics", topic = "Epidemiologic measures"))
  }

  if (grepl("sample size|power calculation|minimum per.group sample|minimum required sample", text)) {
    return(c(section = "Biostatistics", topic = "Sample size and power"))
  }

  if (grepl("t-test|confidence interval|z-test|cohen's d|chi-square|f-statistic|anova|binomial distribution|standard error of the mean", text)) {
    return(c(section = "Biostatistics", topic = "Inference basics"))
  }

  if (grepl("create a vector|sequence of even numbers|repetitions of the value|data.frame|matrix|extract the|missing values", text)) {
    return(c(section = "R", topic = "Core data structures"))
  }

  c(section = "Biostatistics", topic = "Descriptive statistics")
}

.infer_question_difficulty <- function(topic) {
  if (topic %in% c("Core data structures", "Descriptive statistics")) {
    return("beginner")
  }

  if (topic %in% c("Epidemiologic measures", "Inference basics", "Regression modeling")) {
    return("intermediate")
  }

  "advanced"
}

.infer_question_tags <- function(question, expected_output, topic, section) {
  tags <- c(
    gsub("[^a-z0-9]+", "-", tolower(section)),
    gsub("[^a-z0-9]+", "-", tolower(topic))
  )

  result_kind <- if (expected_output %in% c("vector", "matrix", "table", "list", "plot")) {
    expected_output
  } else {
    "numeric"
  }
  tags <- c(tags, result_kind)

  text <- .normalize_question_text(question)

  if (grepl("survival|hazard|kaplan-meier|fine-gray", text)) {
    tags <- c(tags, "survival")
  }
  if (grepl("bayesian|posterior|prior|bayes factor", text)) {
    tags <- c(tags, "bayesian")
  }
  if (grepl("regression|correlation|linear model", text)) {
    tags <- c(tags, "regression")
  }
  if (grepl("risk|odds|sensitivity|specificity|ppv|diagnostic", text)) {
    tags <- c(tags, "epidemiology")
  }

  paste(unique(tags), collapse = ";")
}

.augment_question_metadata <- function(questions) {
  meta <- t(vapply(
    seq_len(nrow(questions)),
    function(i) {
      .infer_question_topic(questions$question[[i]], questions$code[[i]])
    },
    FUN.VALUE = c(section = "", topic = "")
  ))

  questions$section <- meta[, "section"]
  questions$topic <- meta[, "topic"]
  questions$difficulty <- vapply(questions$topic, .infer_question_difficulty, character(1))
  questions$tags <- vapply(
    seq_len(nrow(questions)),
    function(i) {
      .infer_question_tags(
        question = questions$question[[i]],
        expected_output = questions$expected_output[[i]],
        topic = questions$topic[[i]],
        section = questions$section[[i]]
      )
    },
    character(1)
  )

  questions
}

#' Load the Knowledge Repository
#'
#' Reads the packaged knowledge repository used by the learning area and by the
#' question explanation helpers.
#'
#' @return A `data.frame` with `section`, `topic`, `summary`, and
#'   `test_area_reference`.
#' @examples
#' knowledge <- load_knowledge_repository()
#' unique(knowledge$section)
#' @export
load_knowledge_repository <- function() {
  .load_package_csv("knowledge_repository.csv")
}

#' Summarize the Question Bank
#'
#' Produces a compact summary of question-bank coverage by section, topic,
#' difficulty, and expected output type.
#'
#' @param questions_df A question data frame. Defaults to
#'   `load_questions(include_metadata = TRUE)`.
#' @return A named list containing scalar counts and summary tables.
#' @examples
#' summary <- summarize_question_bank()
#' summary$n_questions
#' summary$by_topic
#' @export
summarize_question_bank <- function(questions_df = load_questions(include_metadata = TRUE)) {
  if (!"topic" %in% names(questions_df)) {
    questions_df <- .augment_question_metadata(questions_df)
  }

  result_type <- ifelse(
    questions_df$expected_output %in% c("vector", "matrix", "table", "list", "plot"),
    questions_df$expected_output,
    "numeric"
  )

  by_topic <- list_question_topics(questions_df = questions_df)
  by_difficulty <- stats::aggregate(
    questions_df$id,
    by = list(difficulty = questions_df$difficulty),
    FUN = length
  )
  names(by_difficulty)[names(by_difficulty) == "x"] <- "n_questions"

  by_result_type <- stats::aggregate(
    questions_df$id,
    by = list(result_type = result_type),
    FUN = length
  )
  names(by_result_type)[names(by_result_type) == "x"] <- "n_questions"

  list(
    n_questions = nrow(questions_df),
    n_sections = length(unique(questions_df$section)),
    n_topics = length(unique(questions_df$topic)),
    by_topic = by_topic,
    by_difficulty = by_difficulty[order(by_difficulty$difficulty), , drop = FALSE],
    by_result_type = by_result_type[order(by_result_type$result_type), , drop = FALSE]
  )
}

#' List Question Topics
#'
#' Summarises the derived question-bank metadata by topic.
#'
#' @param questions_df A question data frame. Defaults to
#'   `load_questions(include_metadata = TRUE)`.
#' @param section Optional section filter.
#' @return A `data.frame` with `section`, `topic`, and `n_questions`.
#' @examples
#' list_question_topics()
#' list_question_topics(section = "Biostatistics")
#' @export
list_question_topics <- function(questions_df = load_questions(include_metadata = TRUE),
                                 section = NULL) {
  if (!"topic" %in% names(questions_df)) {
    questions_df <- .augment_question_metadata(questions_df)
  }

  if (!is.null(section)) {
    questions_df <- questions_df[questions_df$section %in% section, , drop = FALSE]
  }

  if (nrow(questions_df) == 0) {
    return(data.frame(
      section = character(),
      topic = character(),
      n_questions = integer(),
      stringsAsFactors = FALSE
    ))
  }

  topic_counts <- stats::aggregate(
    questions_df$id,
    by = list(section = questions_df$section, topic = questions_df$topic),
    FUN = length
  )
  names(topic_counts)[names(topic_counts) == "x"] <- "n_questions"

  topic_counts[order(topic_counts$section, topic_counts$topic), , drop = FALSE]
}

#' Filter Questions
#'
#' Filters the question bank using derived metadata and free-text matching.
#'
#' @param questions_df A question data frame. Defaults to
#'   `load_questions(include_metadata = TRUE)`.
#' @param section Optional section filter.
#' @param topic Optional topic filter.
#' @param difficulty Optional difficulty filter.
#' @param text Optional case-insensitive text filter matched against `question`
#'   and `code`.
#' @param tags Optional tag or tag vector matched against the derived `tags`
#'   column.
#' @return A filtered `data.frame`.
#' @examples
#' filter_questions(topic = "Bayesian inference")
#' filter_questions(difficulty = "advanced", text = "AUC")
#' @export
filter_questions <- function(questions_df = load_questions(include_metadata = TRUE),
                             section = NULL,
                             topic = NULL,
                             difficulty = NULL,
                             text = NULL,
                             tags = NULL) {
  if (!"topic" %in% names(questions_df)) {
    questions_df <- .augment_question_metadata(questions_df)
  }

  keep <- rep(TRUE, nrow(questions_df))

  if (!is.null(section)) {
    keep <- keep & questions_df$section %in% section
  }

  if (!is.null(topic)) {
    keep <- keep & questions_df$topic %in% topic
  }

  if (!is.null(difficulty)) {
    keep <- keep & questions_df$difficulty %in% difficulty
  }

  if (!is.null(text) && nzchar(text)) {
    text_pattern <- tolower(text)
    haystack <- paste(questions_df$question, questions_df$code)
    keep <- keep & grepl(text_pattern, tolower(haystack), fixed = TRUE)
  }

  if (!is.null(tags)) {
    requested_tags <- unique(tolower(tags))
    keep <- keep & vapply(
      strsplit(tolower(questions_df$tags), ";", fixed = TRUE),
      function(question_tags) any(requested_tags %in% question_tags),
      logical(1)
    )
  }

  questions_df[keep, , drop = FALSE]
}

#' Sample Questions
#'
#' Samples one or more questions after applying metadata filters.
#'
#' @param n Number of questions to sample.
#' @param replace Should sampling occur with replacement?
#' @param seed Optional seed for reproducible sampling.
#' @param questions_df A question data frame. Defaults to
#'   `load_questions(include_metadata = TRUE)`.
#' @param section Optional section filter.
#' @param topic Optional topic filter.
#' @param difficulty Optional difficulty filter.
#' @param text Optional text filter.
#' @param tags Optional tag filter.
#' @return A sampled `data.frame`.
#' @examples
#' sample_questions(n = 2, topic = "Prediction model performance", seed = 1)
#' @export
sample_questions <- function(n = 1,
                             replace = FALSE,
                             seed = NULL,
                             questions_df = load_questions(include_metadata = TRUE),
                             section = NULL,
                             topic = NULL,
                             difficulty = NULL,
                             text = NULL,
                             tags = NULL) {
  filtered <- filter_questions(
    questions_df = questions_df,
    section = section,
    topic = topic,
    difficulty = difficulty,
    text = text,
    tags = tags
  )

  if (!is.null(seed)) {
    set.seed(seed)
  }

  if (nrow(filtered) == 0) {
    stop("No questions available for the requested filters.")
  }

  if (!replace && n > nrow(filtered)) {
    stop("Requested sample size exceeds the number of available questions.")
  }

  filtered[sample.int(nrow(filtered), size = n, replace = replace), , drop = FALSE]
}

#' Get an Explanation for a Question
#'
#' Looks up the derived topic for a question and returns the paired knowledge
#' repository note.
#'
#' @param id Question identifier.
#' @param questions_df A question data frame. Defaults to
#'   `load_questions(include_metadata = TRUE)`.
#' @param knowledge_df A knowledge repository data frame. Defaults to
#'   `load_knowledge_repository()`.
#' @return A named list with `id`, `section`, `topic`, `summary`, and
#'   `test_area_reference`.
#' @examples
#' explanation <- get_question_explanation(100)
#' explanation$topic
#' @export
get_question_explanation <- function(id,
                                     questions_df = load_questions(include_metadata = TRUE),
                                     knowledge_df = load_knowledge_repository()) {
  if (!"topic" %in% names(questions_df)) {
    questions_df <- .augment_question_metadata(questions_df)
  }

  row <- questions_df[questions_df$id == id, , drop = FALSE]
  if (nrow(row) == 0) {
    stop("Invalid question id.")
  }

  knowledge_row <- knowledge_df[
    knowledge_df$topic == row$topic[[1]] &
      knowledge_df$section == row$section[[1]],
    ,
    drop = FALSE
  ]

  if (nrow(knowledge_row) == 0) {
    return(list(
      id = row$id[[1]],
      section = row$section[[1]],
      topic = row$topic[[1]],
      summary = sprintf(
        "This question is classified under %s in the %s section.",
        row$topic[[1]],
        row$section[[1]]
      ),
      test_area_reference = sprintf("Question %s", row$id[[1]])
    ))
  }

  list(
    id = row$id[[1]],
    section = knowledge_row$section[[1]],
    topic = knowledge_row$topic[[1]],
    summary = knowledge_row$summary[[1]],
    test_area_reference = knowledge_row$test_area_reference[[1]]
  )
}

#' Validate a Single Question Row
#'
#' Validates a single question definition before it is added to the packaged
#' CSV. This is useful in authoring workflows or pre-commit checks.
#'
#' @param question_row A one-row `data.frame` or named list with `id`,
#'   `question`, `code`, and `expected_output`.
#' @param tolerance Numeric tolerance used when comparing numeric outputs.
#' @return A one-row `data.frame` with validation details and derived metadata.
#' @examples
#' validate_question_row(list(
#'   id = 999,
#'   question = "Compute 1 + 1",
#'   code = "1 + 1",
#'   expected_output = "2"
#' ))
#' @export
validate_question_row <- function(question_row, tolerance = 1e-6) {
  if (is.list(question_row) && !is.data.frame(question_row)) {
    question_row <- as.data.frame(question_row, stringsAsFactors = FALSE)
  }

  required_columns <- c("id", "question", "code", "expected_output")
  if (!is.data.frame(question_row) ||
      nrow(question_row) != 1L ||
      !all(required_columns %in% names(question_row))) {
    stop(
      "question_row must be a one-row data.frame or named list with 'id', 'question', 'code', and 'expected_output'."
    )
  }

  evaluation <- evaluate_answer(
    user_code = question_row$code[[1]],
    expected_output = question_row$expected_output[[1]],
    tolerance = tolerance
  )

  metadata <- .augment_question_metadata(question_row)
  metadata$valid <- isTRUE(evaluation$matches_expected)
  metadata$detail <- if (evaluation$ok) {
    if (metadata$valid[[1]]) "" else paste("got:", toString(evaluation$result))
  } else {
    evaluation$error
  }

  metadata
}
