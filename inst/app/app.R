# This is the main Shiny application for the bioStatAnki package.
#
# The app presents a single question at a time from a set of
# pre-defined bio-statistics exercises.  The user is invited to
# enter R code that computes the answer.  When the "Check answer"
# button is pressed, the code is evaluated and the result is
# compared to the expected answer stored in the dataset.  Feedback
# is shown and the user can move on to the next question.

library(shiny)
library(bioStatAnki)

# Load all questions once at startup
questions_df <- load_questions()

ui <- fluidPage(
  titlePanel("BioStat Anki Quiz"),
  sidebarLayout(
    sidebarPanel(
      h4("Question"),
      textOutput("question_text"),
      tags$hr(),
      textAreaInput(
        inputId = "code_input",
        label = "Enter your R code:",
        value = "",
        rows = 5,
        width = "100%"
      ),
      actionButton("check_btn", "Check answer", class = "btn-primary"),
      tags$br(), tags$br(),
      actionButton("next_btn", "Next question", class = "btn-secondary")
    ),
    mainPanel(
      h4("Feedback"),
      verbatimTextOutput("feedback")
    )
  )
)

server <- function(input, output, session) {
  # Track which question the user is on
  current_index <- reactiveVal(1)

  # Display the current question text
  output$question_text <- renderText({
    questions_df$question[current_index()]
  })

  # When the user presses the check button, evaluate their answer
  observeEvent(input$check_btn, {
    user_code <- input$code_input
    qid <- current_index()
    expected <- questions_df$expected_output[qid]
    correct <- check_answer(user_code, expected)
    if (correct) {
      feedback_text <- "Correct!"
    } else {
      feedback_text <- paste0("Incorrect. Expected: ", expected)
    }
    output$feedback <- renderText({ feedback_text })
  })

  # When the user clicks next, advance to the next question
  observeEvent(input$next_btn, {
    idx <- current_index() + 1
    if (idx > nrow(questions_df)) {
      idx <- 1
    }
    current_index(idx)
    # clear feedback and code input
    output$feedback <- renderText({ "" })
    updateTextAreaInput(session, "code_input", value = "")
  })
}

shinyApp(ui = ui, server = server)