.find_local_package_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = FALSE)

  repeat {
    if (file.exists(file.path(current, "DESCRIPTION")) &&
        dir.exists(file.path(current, "inst", "extdata"))) {
      return(current)
    }

    parent <- dirname(current)
    if (identical(parent, current)) {
      return(NULL)
    }

    current <- parent
  }
}

.load_package_csv <- function(file_name) {
  local_root <- .find_local_package_root()
  if (!is.null(local_root)) {
    csv_path <- file.path(local_root, "inst", "extdata", file_name)
  } else {
    csv_path <- ""
  }

  if (!file.exists(csv_path)) {
    csv_path <- system.file("extdata", file_name, package = "biostatAnki")
  }

  if (!file.exists(csv_path)) {
    stop(sprintf("Package resource '%s' not found.", file_name))
  }

  utils::read.csv(csv_path, stringsAsFactors = FALSE)
}
