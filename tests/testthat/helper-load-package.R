if (!"biostatAnki" %in% loadedNamespaces()) {
  pkgload::load_all(
    path = ".",
    export_all = FALSE,
    helpers = FALSE,
    quiet = TRUE
  )
}
