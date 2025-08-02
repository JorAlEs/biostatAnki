library(shiny)
library(biostatAnki)

# --- data -----------------------------------------------------------
questions_df <- load_questions()
n_questions  <- nrow(questions_df)

# --- ui -------------------------------------------------------------
ui <- fluidPage(
  titlePanel("BioStat Anki Quiz"),
  sidebarLayout(
    sidebarPanel(
      h4("Question"),
      textOutput("question_text"),
      tags$hr(),
      textAreaInput(
        "code_input",
        label = "Enter your R code:",
        value = "",
        rows  = 5,
        width = "100%"
      ),
      actionButton("run_btn",   "Run code",     class = "btn-primary"),
      tags$br(), tags$br(),
      actionButton("check_btn", "Check answer", class = "btn-success"),
      tags$br(), tags$br(),
      actionButton("next_btn",  "Next question", class = "btn-secondary")
    ),
    mainPanel(
      h4("Result"),
      verbatimTextOutput("result_out"),
      tags$hr(),
      h4("Feedback"),
      verbatimTextOutput("feedback_out")
    )
  )
)

# --- server ---------------------------------------------------------
server <- function(input, output, session) {

  # fixed random order for the session
  order_vec  <- sample.int(n_questions)
  pos        <- reactiveVal(1)
  result_val <- reactiveVal(NULL)

  current_id <- reactive(order_vec[pos()])

  # helper: compare numeric/character equality with tolerance
  compare <- function(result, expected) {
    exp_num <- suppressWarnings(as.numeric(expected))
    if (!is.na(exp_num) && is.numeric(result))
      return(isTRUE(all.equal(as.numeric(result), exp_num, tolerance = 1e-6)))
    if (is.character(expected) && is.character(result))
      return(identical(trimws(result), trimws(expected)))
    identical(result, expected)
  }

  # show question
  output$question_text <- renderText({
    questions_df$question[current_id()]
  })

  # run code
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
      output$feedback_out <- renderText("")  # clear previous feedback
    }
  })

  # check answer
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

  # next question
  observeEvent(input$next_btn, {
    pos_new <- ifelse(pos() == n_questions, 1, pos() + 1)
    pos(pos_new)
    updateTextAreaInput(session, "code_input", value = "")
    result_val(NULL)
    output$result_out   <- renderText("")
    output$feedback_out <- renderText("")
  })
}

shinyApp(ui, server)
