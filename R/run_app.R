#' Launch the biostatAnki Shiny App
#'
#' This helper starts the Shiny application shipped with **biostatAnki**.
#' It performs extra validation (dependencies, directory, interactive
#' session), chooses smart defaults for host/port, and always opens the
#' browser unless run in a non-interactive session (e.g. Rscript).
#'
#' @param host Character. Network interface to bind.  
#'             Default "0.0.0.0" so it works inside Docker or on-prem servers. 
#' @param port Integer. Port to listen on.  
#'             Default uses the `biostatAnki_PORT` env-var when set, else
#'             a random available port. 
#' @param launch.browser Logical. Force opening the system browser.  
#'             Defaults to TRUE in interactive sessions.
#' @param quiet Logical. If TRUE, suppresses the startup banner.
#' @param ...  Further arguments passed to `shiny::runApp()`.
#'
#' @return Invisibly returns the value from `shiny::runApp()`.
#' @export
run_app <- function(host = "0.0.0.0",
                    port = NULL,
                    launch.browser = interactive(),
                    quiet = FALSE,
                    ...) {
  
  # ---- 1. Dependency check -----------------------------------------------
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Package 'shiny' is required but not installed.", call. = FALSE)
  }
  
  # ---- 2. Locate app directory -------------------------------------------
  app_dir <- system.file("app", package = "biostatAnki")
  if (app_dir == "") {
    stop("Cannot find Shiny app directory. Try reinstalling 'biostatAnki'.",
         call. = FALSE)
  }
  
  # ---- 3. Choose port -----------------------------------------------------
  if (is.null(port)) {
    port_env <- Sys.getenv("biostatAnki_PORT", unset = NA)
    port     <- if (is.na(port_env)) httpuv::randomPort() else as.integer(port_env)
  }
  
  # ---- 4. Friendly banner -------------------------------------------------
  if (!quiet) {
    msg <- sprintf(
      "\n▶ Starting biostatAnki app  •  Host: %s  •  Port: %s\n", host, port
    )
    cat(msg)
  }
  
  # ---- 5. Launch ----------------------------------------------------------
  shiny::runApp(
    appDir         = app_dir,
    host           = host,
    port           = port,
    launch.browser = launch.browser,
    ...
  )
}
