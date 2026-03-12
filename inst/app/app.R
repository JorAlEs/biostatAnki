library(shiny)
library(biostatAnki)

# --- data -----------------------------------------------------------
questions_df <- load_questions()
knowledge_path <- system.file("extdata", "knowledge_repository.csv", package = "biostatAnki")
if (knowledge_path == "") {
  stop("Knowledge repository file not found in package resources.")
}
knowledge_df <- utils::read.csv(knowledge_path, stringsAsFactors = FALSE)
knowledge_sections <- unique(knowledge_df$section)

# --- modules --------------------------------------------------------
mod_testing_ui <- function(id) {
  ns <- NS(id)

  sidebarLayout(
    sidebarPanel(
      h4("Question"),
      textOutput(ns("question_text")),
      tags$hr(),
      textAreaInput(
        ns("code_input"),
        label = "Enter your R code:",
        value = "",
        rows  = 5,
        width = "100%"
      ),
      actionButton(ns("run_btn"),   "Run code",      class = "btn-primary"),
      tags$br(), tags$br(),
      actionButton(ns("check_btn"), "Check answer",  class = "btn-success"),
      tags$br(), tags$br(),
      actionButton(ns("next_btn"),  "Next question", class = "btn-secondary")
    ),
    mainPanel(
      h4("Result"),
      verbatimTextOutput(ns("result_out")),
      tags$hr(),
      h4("Feedback"),
      verbatimTextOutput(ns("feedback_out"))
    )
  )
}

mod_testing_server <- function(id, questions_df) {
  moduleServer(id, function(input, output, session) {
    order_vec  <- sample.int(nrow(questions_df))
    pos        <- reactiveVal(1)
    result_val <- reactiveVal(NULL)
    current_id <- reactive(order_vec[pos()])

    compare <- function(result, expected) {
      if (expected == "vector") return(is.atomic(result) && is.null(dim(result)))
      if (expected == "matrix") return(is.matrix(result))

      exp_num <- suppressWarnings(as.numeric(expected))
      if (!is.na(exp_num) && is.numeric(result)) {
        return(isTRUE(all.equal(as.numeric(result), exp_num, tolerance = 1e-6)))
      }

      if (is.character(expected) && is.character(result)) {
        return(identical(trimws(result), trimws(expected)))
      }

      identical(result, expected)
    }

    output$question_text <- renderText({
      questions_df$question[current_id()]
    })

    observeEvent(input$run_btn, {
      res <- try(
        eval(parse(text = input$code_input), envir = new.env(parent = globalenv())),
        silent = TRUE
      )

      if (inherits(res, "try-error")) {
        result_val(NULL)
        output$result_out   <- renderText("Error while executing your code.")
        output$feedback_out <- renderText("")
      } else {
        result_val(res)
        output$result_out <- renderText(
          paste(capture.output(print(res)), collapse = "\n")
        )
        output$feedback_out <- renderText("")
      }
    })

    observeEvent(input$check_btn, {
      res <- result_val()
      if (is.null(res)) {
        output$feedback_out <- renderText("Please run your code first.")
        return()
      }

      expected <- questions_df$expected_output[current_id()]
      if (compare(res, expected)) {
        output$feedback_out <- renderText("✅ Correct!")
      } else {
        output$feedback_out <- renderText(paste0("❌ Incorrect. Expected: ", expected))
      }
    })

    observeEvent(input$next_btn, {
      pos_new <- ifelse(pos() == nrow(questions_df), 1, pos() + 1)
      pos(pos_new)
      updateTextAreaInput(session, "code_input", value = "")
      result_val(NULL)
      output$result_out   <- renderText("")
      output$feedback_out <- renderText("")
    })
  })
}

mod_learning_ui <- function(id, sections) {
  ns <- NS(id)

  tagList(
    p(
      "This area explains the concepts used in the Testing Area. ",
      "The loop can extend this repository with new learning notes."
    ),
    selectInput(
      ns("section_input"),
      "Knowledge section:",
      choices  = sections,
      selected = sections[[1]]
    ),
    uiOutput(ns("knowledge_cards"))
  )
}

mod_learning_server <- function(id, knowledge_df) {
  moduleServer(id, function(input, output, session) {
    output$knowledge_cards <- renderUI({
      req(input$section_input)
      section_df <- knowledge_df[knowledge_df$section == input$section_input, , drop = FALSE]

      if (nrow(section_df) == 0) {
        return(tags$p("No entries available for this section yet."))
      }

      tagList(lapply(seq_len(nrow(section_df)), function(i) {
        wellPanel(
          h4(section_df$topic[[i]]),
          p(section_df$summary[[i]]),
          p(tags$strong("Covered in testing area: "), section_df$test_area_reference[[i]])
        )
      }))
    })
  })
}

mod_sandbox_ui <- function(id) {
  ns <- NS(id)

  fluidRow(
    column(
      width = 4,
      wellPanel(
        h4("Mock Data Builder"),
        selectInput(
          ns("dataset_select"),
          "Dataset template:",
          choices = c("Clinical cohort", "Case-control study", "Two-arm trial")
        ),
        numericInput(
          ns("n_input"),
          "Number of rows:",
          value = 120,
          min = 20,
          max = 1000,
          step = 10
        ),
        numericInput(
          ns("seed_input"),
          "Random seed:",
          value = 123,
          min = 1,
          step = 1
        ),
        actionButton(
          ns("generate_data_btn"),
          "Generate mock data",
          class = "btn-primary"
        ),
        tags$hr(),
        h4("Toolset"),
        selectInput(
          ns("analysis_select"),
          "Analysis toolset:",
          choices = c(
            "Descriptive stats by group",
            "Two-sample t-test (biomarker by group)",
            "Logistic regression (outcome ~ age + biomarker + group)",
            "Risk and odds measures (2x2 exposure-outcome)"
          )
        ),
        actionButton(
          ns("run_selected_btn"),
          "Generate selected output",
          class = "btn-success"
        ),
        tags$hr(),
        h4("Try Your Own Code"),
        p("Use `mock_data` as the input dataset in your code."),
        textAreaInput(
          ns("custom_code"),
          "Custom R code:",
          value = "head(mock_data)",
          rows = 8,
          width = "100%"
        ),
        actionButton(
          ns("run_custom_btn"),
          "Run custom code",
          class = "btn-secondary"
        )
      )
    ),
    column(
      width = 8,
      h4("Mock data preview"),
      tableOutput(ns("data_preview")),
      tags$hr(),
      h4("Selected output"),
      verbatimTextOutput(ns("analysis_out")),
      tags$hr(),
      h4("Script snippet"),
      verbatimTextOutput(ns("script_snippet_out")),
      tags$hr(),
      h4("Required libraries"),
      verbatimTextOutput(ns("libraries_out")),
      tags$hr(),
      h4("Custom code output"),
      verbatimTextOutput(ns("custom_out"))
    )
  )
}

mod_sandbox_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    make_mock_data <- function(dataset_name, n, seed) {
      set.seed(seed)

      if (dataset_name == "Clinical cohort") {
        group <- sample(c("Control", "Treatment"), n, replace = TRUE)
        age <- pmax(18, round(rnorm(n, mean = 55, sd = 10)))
        biomarker <- round(rnorm(n, mean = 50 + ifelse(group == "Treatment", -3, 0), sd = 8), 1)
        linpred <- -4 + 0.05 * age + 0.04 * biomarker + ifelse(group == "Treatment", -0.4, 0)
        outcome <- stats::rbinom(n, size = 1, prob = stats::plogis(linpred))
        exposure <- ifelse(biomarker > stats::median(biomarker), "Yes", "No")
      } else if (dataset_name == "Case-control study") {
        outcome <- stats::rbinom(n, size = 1, prob = 0.45)
        group <- ifelse(outcome == 1, "Case", "Control")
        age <- pmax(18, round(rnorm(n, mean = 58 + 4 * outcome, sd = 9)))
        exposure <- ifelse(stats::runif(n) < ifelse(outcome == 1, 0.65, 0.35), "Yes", "No")
        biomarker <- round(rnorm(n, mean = 52 + 5 * outcome + 2 * (exposure == "Yes"), sd = 7), 1)
      } else {
        group <- sample(c("ArmA", "ArmB"), n, replace = TRUE)
        age <- pmax(18, round(rnorm(n, mean = 50, sd = 12)))
        baseline <- rnorm(n, mean = 100, sd = 12)
        change <- rnorm(n, mean = ifelse(group == "ArmB", -6, -2), sd = 5)
        biomarker <- round(baseline + change, 1)
        outcome <- as.integer(change <= -5)
        exposure <- ifelse(group == "ArmB", "Yes", "No")
      }

      data.frame(
        id = seq_len(n),
        group = group,
        age = age,
        biomarker = biomarker,
        exposure = exposure,
        outcome = outcome,
        stringsAsFactors = FALSE
      )
    }

    analysis_template <- function(analysis_name) {
      if (analysis_name == "Descriptive stats by group") {
        return(paste(
          "head(mock_data)",
          "aggregate(biomarker ~ group, data = mock_data, FUN = mean)",
          sep = "\n"
        ))
      }

      if (analysis_name == "Two-sample t-test (biomarker by group)") {
        return("stats::t.test(biomarker ~ group, data = mock_data)")
      }

      if (analysis_name == "Logistic regression (outcome ~ age + biomarker + group)") {
        return(paste(
          "fit <- stats::glm(outcome ~ age + biomarker + group, data = mock_data, family = stats::binomial())",
          "summary(fit)$coefficients",
          sep = "\n"
        ))
      }

      paste(
        "tab <- table(factor(mock_data$exposure, levels = c('No', 'Yes')), factor(mock_data$outcome, levels = c(0, 1)))",
        "tab",
        "a <- tab['Yes', '1']; b <- tab['Yes', '0']; c <- tab['No', '1']; d <- tab['No', '0']",
        "risk_ratio <- (a/(a+b)) / (c/(c+d))",
        "odds_ratio <- (a*d) / (b*c)",
        "c(risk_ratio = risk_ratio, odds_ratio = odds_ratio)",
        sep = "\n"
      )
    }

    dataset_snippet <- function(dataset_name) {
      paste(
        "set.seed(<seed>)",
        paste0("n <- ", input$n_input),
        switch(
          dataset_name,
          "Clinical cohort" = "group <- sample(c('Control', 'Treatment'), n, replace = TRUE)",
          "Case-control study" = "group <- ifelse(stats::rbinom(n, 1, 0.45) == 1, 'Case', 'Control')",
          "Two-arm trial" = "group <- sample(c('ArmA', 'ArmB'), n, replace = TRUE)"
        ),
        "age <- pmax(18, round(rnorm(n, mean = 55, sd = 10)))",
        "biomarker <- round(rnorm(n, mean = 50, sd = 8), 1)",
        "exposure <- ifelse(biomarker > median(biomarker), 'Yes', 'No')",
        "outcome <- stats::rbinom(n, 1, stats::plogis(-4 + 0.05 * age + 0.04 * biomarker))",
        "mock_data <- data.frame(group, age, biomarker, exposure, outcome)",
        sep = "\n"
      )
    }

    run_selected_analysis <- function(data, analysis_name, dataset_name) {
      if (analysis_name == "Descriptive stats by group") {
        groups <- unique(data$group)
        summary_df <- do.call(rbind, lapply(groups, function(g) {
          sub <- data[data$group == g, , drop = FALSE]
          data.frame(
            group = g,
            n = nrow(sub),
            mean_age = round(mean(sub$age), 2),
            sd_age = round(stats::sd(sub$age), 2),
            mean_biomarker = round(mean(sub$biomarker), 2),
            outcome_rate = round(mean(sub$outcome), 3),
            stringsAsFactors = FALSE
          )
        }))

        return(list(
          result_text = paste(capture.output(print(summary_df, row.names = FALSE)), collapse = "\n"),
          libraries = c("stats (base R)", "utils (base R)"),
          snippet = paste(
            dataset_snippet(dataset_name),
            "",
            "# Descriptive summary by group",
            "aggregate(cbind(age, biomarker, outcome) ~ group, data = mock_data,",
            "          FUN = function(x) round(mean(x), 3))",
            sep = "\n"
          )
        ))
      }

      if (analysis_name == "Two-sample t-test (biomarker by group)") {
        t_out <- stats::t.test(biomarker ~ group, data = data)
        return(list(
          result_text = paste(capture.output(print(t_out)), collapse = "\n"),
          libraries = c("stats (base R)"),
          snippet = paste(
            dataset_snippet(dataset_name),
            "",
            "# Two-sample t-test",
            "stats::t.test(biomarker ~ group, data = mock_data)",
            sep = "\n"
          )
        ))
      }

      if (analysis_name == "Logistic regression (outcome ~ age + biomarker + group)") {
        fit <- stats::glm(outcome ~ age + biomarker + group, data = data, family = stats::binomial())
        coef_tbl <- summary(fit)$coefficients

        return(list(
          result_text = paste(capture.output(print(coef_tbl)), collapse = "\n"),
          libraries = c("stats (base R)"),
          snippet = paste(
            dataset_snippet(dataset_name),
            "",
            "# Logistic regression",
            "fit <- stats::glm(outcome ~ age + biomarker + group,",
            "                  data = mock_data, family = stats::binomial())",
            "summary(fit)$coefficients",
            sep = "\n"
          )
        ))
      }

      table_2x2 <- table(
        factor(data$exposure, levels = c("No", "Yes")),
        factor(data$outcome, levels = c(0, 1))
      )
      a <- as.numeric(table_2x2["Yes", "1"])
      b <- as.numeric(table_2x2["Yes", "0"])
      c <- as.numeric(table_2x2["No", "1"])
      d <- as.numeric(table_2x2["No", "0"])

      if (any(c(a, b, c, d) == 0)) {
        a <- a + 0.5
        b <- b + 0.5
        c <- c + 0.5
        d <- d + 0.5
      }

      risk_ratio <- (a / (a + b)) / (c / (c + d))
      odds_ratio <- (a * d) / (b * c)
      measures_df <- data.frame(
        measure = c("Risk ratio", "Odds ratio"),
        value = round(c(risk_ratio, odds_ratio), 4),
        stringsAsFactors = FALSE
      )

      list(
        result_text = paste(
          c(
            "2x2 table (Exposure x Outcome):",
            capture.output(print(table_2x2)),
            "",
            capture.output(print(measures_df, row.names = FALSE))
          ),
          collapse = "\n"
        ),
        libraries = c("stats (base R)", "epitools (optional for advanced epidemiology workflows)"),
        snippet = paste(
          dataset_snippet(dataset_name),
          "",
          "# Risk ratio and odds ratio from a 2x2 table",
          "tab <- table(factor(mock_data$exposure, levels = c('No', 'Yes')),",
          "             factor(mock_data$outcome, levels = c(0, 1)))",
          "a <- tab['Yes', '1']; b <- tab['Yes', '0']; c <- tab['No', '1']; d <- tab['No', '0']",
          "risk_ratio <- (a/(a+b)) / (c/(c+d))",
          "odds_ratio <- (a*d) / (b*c)",
          "data.frame(risk_ratio = risk_ratio, odds_ratio = odds_ratio)",
          sep = "\n"
        )
      )
    }

    mock_data <- eventReactive(input$generate_data_btn, {
      n <- as.integer(input$n_input)
      if (is.na(n) || n < 20) {
        n <- 120
      }

      make_mock_data(
        dataset_name = input$dataset_select,
        n = n,
        seed = as.integer(input$seed_input)
      )
    }, ignoreNULL = FALSE)

    observeEvent(input$analysis_select, {
      updateTextAreaInput(
        session = session,
        inputId = "custom_code",
        value = analysis_template(input$analysis_select)
      )
    }, ignoreInit = FALSE)

    output$data_preview <- renderTable({
      utils::head(mock_data(), 10)
    }, rownames = FALSE)

    analysis_result <- eventReactive(input$run_selected_btn, {
      run_selected_analysis(
        data = mock_data(),
        analysis_name = input$analysis_select,
        dataset_name = input$dataset_select
      )
    })

    output$analysis_out <- renderText({
      if (input$run_selected_btn < 1) {
        return("Choose a toolset and click 'Generate selected output'.")
      }

      analysis_result()$result_text
    })

    output$script_snippet_out <- renderText({
      if (input$run_selected_btn < 1) {
        return("The script snippet appears after generating a selected output.")
      }

      analysis_result()$snippet
    })

    output$libraries_out <- renderText({
      if (input$run_selected_btn < 1) {
        return("The required libraries list appears after generating a selected output.")
      }

      paste(analysis_result()$libraries, collapse = "\n")
    })

    custom_result <- eventReactive(input$run_custom_btn, {
      env <- new.env(parent = globalenv())
      env$mock_data <- mock_data()
      env$df <- mock_data()

      res <- try(eval(parse(text = input$custom_code), envir = env), silent = TRUE)
      if (inherits(res, "try-error")) {
        return("Error while executing custom code.")
      }

      paste(capture.output(print(res)), collapse = "\n")
    })

    output$custom_out <- renderText({
      if (input$run_custom_btn < 1) {
        return("Run custom code to see output.")
      }

      custom_result()
    })
  })
}

# --- ui -------------------------------------------------------------
ui <- fluidPage(
  titlePanel("BioStat Anki"),
  tabsetPanel(
    id = "main_sheets",
    tabPanel(
      "Testing Area",
      mod_testing_ui("testing_area")
    ),
    tabPanel(
      "Learning Area",
      mod_learning_ui("learning_area", knowledge_sections)
    ),
    tabPanel(
      "Sandbox",
      mod_sandbox_ui("sandbox_area")
    )
  )
)

# --- server ---------------------------------------------------------
server <- function(input, output, session) {
  mod_testing_server("testing_area", questions_df)
  mod_learning_server("learning_area", knowledge_df)
  mod_sandbox_server("sandbox_area")
}

shinyApp(ui, server)
