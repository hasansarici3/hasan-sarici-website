read_projects <- function(path = "data/projects.csv") {

  x <- read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    fileEncoding = "UTF-8"
  )

  x$start_year <- as.integer(x$start_year)
  x$end_year <- suppressWarnings(as.integer(x$end_year))
  x$external_funding <- as.logical(x$external_funding)

  x
}

project_counts <- function(x) {

  list(
    total = nrow(x),
    ongoing = sum(x$status == "ongoing"),
    completed = sum(x$status == "completed"),
    externally_funded = sum(x$external_funding, na.rm = TRUE)
  )
}

project_value <- function(x) {
  if (length(x) == 0 || is.na(x) || !nzchar(trimws(x))) return("")
  trimws(x)
}

render_projects <- function(x, status = NULL, lang = "tr") {

  d <- x

  if (!is.null(status)) {
    d <- d[d$status == status, , drop = FALSE]
  }

  d <- d[order(d$display_order), , drop = FALSE]

  if (nrow(d) == 0) return(invisible(NULL))

  for (i in seq_len(nrow(d))) {

    row <- d[i, ]

    title <- if (lang == "tr") row$title_tr else row$title_en
    funding <- if (lang == "tr") row$funding_tr else row$funding_en
    role <- if (lang == "tr") row$role_tr else row$role_en
    date <- if (lang == "tr") row$date_tr else row$date_en
    area <- if (lang == "tr") row$area_tr else row$area_en

    status_label <- if (lang == "tr") {
      if (row$status == "ongoing") "Devam ediyor" else "Tamamlandı"
    } else {
      if (row$status == "ongoing") "Ongoing" else "Completed"
    }

    role_label <- if (lang == "tr") "Rol" else "Role"
    funding_label <- if (lang == "tr") "Destek" else "Funding"
    date_label <- if (lang == "tr") "Dönem" else "Period"

    cat("::: {.project-card}\n")

    cat("::: {.project-card-header}\n")

    cat("::: {.project-status}\n")
    cat(status_label, "\n")
    cat(":::\n")

    cat("::: {.project-year}\n")
    cat(row$start_year, "\n")
    cat(":::\n")

    cat(":::\n\n")

    cat("### ", project_value(title), "\n\n", sep = "")

    cat("::: {.project-area}\n")
    cat(project_value(area), "\n")
    cat(":::\n\n")

    cat("::: {.project-meta-grid}\n")

    cat("::: {.project-meta-item}\n")
    cat("**", funding_label, "**\n\n", sep = "")
    cat(project_value(funding), "\n")
    cat(":::\n")

    cat("::: {.project-meta-item}\n")
    cat("**", role_label, "**\n\n", sep = "")
    cat(project_value(role), "\n")
    cat(":::\n")

    cat("::: {.project-meta-item}\n")
    cat("**", date_label, "**\n\n", sep = "")
    cat(project_value(date), "\n")
    cat(":::\n")

    cat(":::\n")

    cat(":::\n\n")
  }

  invisible(NULL)
}
