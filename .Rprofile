renv_activate_path <- "renv/activate.R"
should_activate_renv <- interactive() || identical(
  tolower(Sys.getenv("BIOSTATANKI_ACTIVATE_RENV", unset = "false")),
  "true"
)

if (should_activate_renv && file.exists(renv_activate_path)) {
  source(renv_activate_path)
}
