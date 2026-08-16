read_publications <- function(path = "data/publications.csv") {
  x <- read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    fileEncoding = "UTF-8"
  )

  x$year <- as.integer(x$year)
  x
}

publication_counts <- function(x) {
  list(
    peer_reviewed = sum(x$category == "peer_reviewed"),
    under_review = sum(x$category == "under_review"),
    books = sum(x$category %in% c("book", "book_chapter"))
  )
}

clean_value <- function(x) {
  if (is.na(x) || !nzchar(trimws(x))) return("")
  trimws(x)
}

pipeline_status_label <- function(status, lang = "tr") {
  status <- clean_value(status)

  if (status == "peer_review") {
    return(if (lang == "tr") "Hakem değerlendirmesinde" else "In peer review")
  }

  if (status == "revising") {
    return(if (lang == "tr") "Revizyon / yeniden gönderim hazırlığı" else "Revision / preparing resubmission")
  }

  if (status == "submitted") {
    return(if (lang == "tr") "Gönderildi / editoryal süreçte" else "Submitted / in editorial process")
  }

  if (lang == "tr") "Yayın sürecinde" else "In publication process"
}

render_publications <- function(x, category, lang = "tr") {

  if (category == "books") {
    d <- x[x$category %in% c("book", "book_chapter"), ]
  } else {
    d <- x[x$category == category, ]
  }

  sort_year <- ifelse(is.na(d$year), -Inf, d$year)
  d <- d[order(-sort_year, d$display_order), , drop = FALSE]

  if (nrow(d) == 0) return(invisible(NULL))

  for (i in seq_len(nrow(d))) {

    row <- d[i, ]

    cat("::: {.publication-card}\n")

    cat("::: {.publication-card-top}\n")

    if (!is.na(row$year)) {
      cat("::: {.publication-year}\n")
      cat(row$year, "\n")
      cat(":::\n")
    }

    if (row$category == "peer_reviewed" && nzchar(clean_value(row$scope))) {
      scope_label <- if (lang == "tr") {
        if (row$scope == "international") "Uluslararası hakemli" else "Ulusal hakemli"
      } else {
        if (row$scope == "international") "International peer-reviewed" else "National peer-reviewed"
      }

      cat("::: {.publication-tag}\n")
      cat(scope_label, "\n")
      cat(":::\n")
    }

    if (row$category == "under_review") {
      cat("::: {.publication-tag .publication-tag-review}\n")
      cat(pipeline_status_label(row$status, lang), "\n")
      cat(":::\n")
    }

    cat(":::\n\n")

    cat("### ", clean_value(row$title), "\n\n", sep = "")

    authors <- clean_value(row$authors)

    if (nzchar(authors)) {
      cat("::: {.publication-authors}\n")
      cat(authors, "\n")
      cat(":::\n\n")
    }

    venue <- clean_value(row$venue)
    volume_issue <- clean_value(row$volume_issue)
    pages <- clean_value(row$pages)

    if (row$category == "peer_reviewed") {

      metadata <- venue

      if (nzchar(volume_issue)) {
        metadata <- paste0(metadata, ", ", volume_issue)
      }

      if (nzchar(pages)) {
        metadata <- paste0(metadata, ", ", pages)
      }

      cat("::: {.publication-meta}\n")
      cat(metadata, "\n")
      cat(":::\n\n")

      doi <- clean_value(row$doi)

      if (nzchar(doi)) {
        doi_label <- if (lang == "tr") "DOI'yi aç ↗" else "Open DOI ↗"
        cat("::: {.publication-links}\n")
        cat("[", doi_label, "](https://doi.org/", doi, "){target=\"_blank\" rel=\"noopener\"}\n", sep = "")
        cat(":::\n\n")
      }

    } else if (row$category == "under_review") {

      cat("::: {.publication-meta}\n")

      if (row$status == "revising") {
        cat(if (lang == "tr") {
          "Metin, bir sonraki gönderim için revize edilmektedir.\n"
        } else {
          "The manuscript is being revised for its next submission.\n"
        })
      } else if (nzchar(venue)) {
        journal_prefix <- if (lang == "tr") "Güncel dergi:" else "Current journal:"
        cat(journal_prefix, " *", venue, "*\n", sep = "")
      }

      cat(":::\n\n")

    } else {

      contribution <- if (lang == "tr") {
        clean_value(row$contribution_tr)
      } else {
        clean_value(row$contribution_en)
      }

      cat("::: {.publication-meta}\n")
      cat(venue, "\n\n")

      if (nzchar(contribution)) {
        cat("**", contribution, "**\n", sep = "")
      }

      cat(":::\n\n")
    }

    cat(":::\n\n")
  }

  invisible(NULL)
}

render_featured_publications <- function(x, lang = "tr", n = 3) {

  d <- x[
    x$category == "peer_reviewed" & x$status == "published",
    ,
    drop = FALSE
  ]

  sort_year <- ifelse(is.na(d$year), -Inf, d$year)
  d <- d[order(-sort_year, d$display_order), , drop = FALSE]
  d <- head(d, n)

  if (nrow(d) == 0) return(invisible(NULL))

  cat("::: {.featured-publications-grid}\n")

  for (i in seq_len(nrow(d))) {
    row <- d[i, ]

    cat("::: {.featured-publication}\n")

    cat("::: {.featured-publication-meta}\n")
    cat(row$year, " · ", clean_value(row$venue), "\n", sep = "")
    cat(":::\n\n")

    cat("### ", clean_value(row$title), "\n\n", sep = "")

    authors <- clean_value(row$authors)
    if (nzchar(authors)) {
      cat("::: {.featured-publication-authors}\n")
      cat(authors, "\n")
      cat(":::\n\n")
    }

    doi <- clean_value(row$doi)
    if (nzchar(doi)) {
      cat("::: {.featured-publication-link}\n")
      cat("[DOI ↗](https://doi.org/", doi, "){target=\"_blank\" rel=\"noopener\"}\n", sep = "")
      cat(":::\n")
    }

    cat(":::\n\n")
  }

  cat(":::\n")

  invisible(NULL)
}
