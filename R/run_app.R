##' Launch the BioStat Anki Shiny App
##'
##' This function starts the Shiny application bundled within the
##' bioStatAnki package.  It simply finds the location of the app
##' directory inside the installed package and calls `shiny::runApp()`
##' to launch it.  Additional arguments can be passed to control
##' options such as the host and port.
##'
##' @param ... Additional parameters passed to `shiny::runApp()`,
##'   such as `host` or `port`.
##' @return This function is called for its side effect of launching
##'   the Shiny application.  It does not return a value.
##' @export
run_app <- function(...) {
  app_dir <- system.file("app", package = "bioStatAnki")
  if (app_dir == "") {
    stop("Could not find app directory. Try re-installing `bioStatAnki`.", call. = FALSE)
  }
  shiny::runApp(app_dir, ...)
}