#' Use RStudio
#'
#' Creates an `.Rproj` file and adds RStudio files to `.gitignore`
#' and `.Rbuildignore`.
#'
#' @export
use_rstudio <- function() {
  use_template(
    "template.Rproj",
    paste0(project_name(), ".Rproj")
  )

  use_git_ignore(".Rproj.user")
  if (is_package()) {
    use_build_ignore(c(paste0(project_name(), ".Rproj"), ".Rproj.user"))
  }

  invisible(TRUE)
}

#' Don't save/load user workspace between sessions
#'
#' R can save and reload the user's workspace between sessions via an `.RData`
#' file in the current directory. However, long-term reproducibility is enhanced
#' when you turn this feature off and clear R's memory at every restart.
#' Starting with a blank slate provides timely feedback that encourages the
#' development of scripts that are complete and self-contained. More detail can
#' be found in the blog post [Project-oriented
#' workflow](https://www.tidyverse.org/articles/2017/12/workflow-vs-script/).
#'
#' Only `use_blank_slate("project")` is automated so far, since RStudio
#' currently only supports modification of user-level or global options via the
#' user interface.
#'
#' @inheritParams edit
#'
#' @export
use_blank_slate <- function(scope = c("user", "project")) {
  scope <- match.arg(scope)

  if (scope == "user") { # nocov start
    todo(
      "To start ALL RStudio sessions with a blank slate, ",
      "you must set this interactively, for now."
    )
    todo(
      "In Global Options > General, ",
      "do NOT check \"Restore .RData into workspace at startup\"."
    )
    todo(
      "In Global Options > General, ",
      "set \"Save workspace to .RData on exit\" to \"Never\"."
    )
    todo(
      "Call `use_blank_slate(\"project\")` to opt in to the blank slate ",
      "workflow in this project."
    )
    return(invisible())
  } # nocov end

  if (!is_rstudio_project()) {
    stop(project_name(), " is not an RStudio Project", call. = FALSE)
  }

  rproj_fields <- modify_rproj(
    proj_path(rproj_path()),
    list(RestoreWorkspace = "No", SaveWorkspace = "No")
  )
  write_utf8(proj_path(rproj_path()), serialize_rproj(rproj_fields))
  restart_rstudio("Restart RStudio with a blank slate?")

  invisible()
}

# Is base_path an RStudio Project?
is_rstudio_project <- function(base_path = proj_get()) {
  res <- tryCatch(
    rprojroot::find_rstudio_root_file(path = base_path),
    error = function(e) NA
  )
  !is.na(res)
}

rproj_path <- function(base_path = proj_get()) {
  rproj_path <- dir(base_path, pattern = "\\.Rproj$")
  if (length(rproj_path) > 1) {
    stop("Multiple .Rproj files found", call. = FALSE)
  }
  if (length(rproj_path) == 1) rproj_path else NA_character_
}

# Is base_path open in RStudio?
in_rstudio <- function(base_path = proj_get()) {
  if (!rstudioapi::isAvailable()) {
    return(FALSE)
  }

  if (!rstudioapi::hasFun("getActiveProject")) {
    return(FALSE)
  }

  proj <- rstudioapi::getActiveProject()

  normalizePath(proj) == normalizePath(base_path)
}

in_rstudio_server <- function() {
  if (!rstudioapi::isAvailable()) {
    return(FALSE)
  }
  identical(rstudioapi::versionInfo()$mode, "server")
}

parse_rproj <- function(file) {
  lines <- as.list(readLines(file))
  has_colon <- grepl(":", lines)
  fields <- lapply(lines[has_colon], function(x) strsplit(x, split = ": ")[[1]])
  lines[has_colon] <- vapply(fields, `[[`, "character", 2)
  names(lines)[has_colon] <- vapply(fields, `[[`, "character", 1)
  names(lines)[!has_colon] <- ""
  lines
}

modify_rproj <- function(file, update) {
  utils::modifyList(parse_rproj(file), update)
}

serialize_rproj <- function(fields) {
  named <- nzchar(names(fields))
  as.character(ifelse(named, paste0(names(fields), ": ", fields), fields))
}

# Must be last command run
restart_rstudio <- function(message = NULL) {
  if (!in_rstudio(proj_get())) {
    return(FALSE)
  }

  if (!interactive()) {
    return(FALSE)
  }

  if (!is.null(message)) {
    todo(message)
  }

  if (!rstudioapi::hasFun("openProject")) {
    return(FALSE)
  }

  if (nope(todo_bullet(), " Restart now?")) {
    return(FALSE)
  }

  rstudioapi::openProject(proj_get())
}
