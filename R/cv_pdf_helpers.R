source("R/cv_helpers.R")
pdf_cv_data <- function() {
  x <- load_cv_data()
  x$conferences <- cv_read("data/conferences.csv")
  x
}

pdf_txt <- function(x) {
  if (length(x) == 0 || is.na(x)) return("")
  trimws(as.character(x))
}

pdf_authors <- function(x) {
  x <- pdf_txt(x)
  if (!nzchar(x)) return("")

  x <- trimws(x)
  x <- gsub("\\s+\\.", ".", x)

  if (grepl("[[:alpha:]ÇĞİÖŞÜçğıöşü]$", x)) {
    x <- paste0(x, ".")
  }

  x
}

pdf_interests <- function(x, lang = "tr") {
  x <- x[order(x$order), , drop = FALSE]
  field <- paste0("label_", lang)
  for (i in seq_len(nrow(x))) {
    cat("- ", pdf_txt(x[[field]][i]), "\n", sep = "")
  }
}

pdf_experience <- function(x, lang = "tr") {
  x <- x[order(x$order), , drop = FALSE]
  for (i in seq_len(nrow(x))) {
    period <- x[[paste0("period_", lang)]][i]
    position <- x[[paste0("position_", lang)]][i]
    unit <- x[[paste0("unit_", lang)]][i]
    cat("**", pdf_txt(period), " | ", pdf_txt(position), "**  \n", sep = "")
    cat(pdf_txt(x$institution[i]), " - ", pdf_txt(unit), "\n\n", sep = "")
  }
}

pdf_education <- function(x, lang = "tr") {
  x <- x[order(x$order), , drop = FALSE]
  for (i in seq_len(nrow(x))) {
    degree <- x[[paste0("degree_", lang)]][i]
    field <- x[[paste0("field_", lang)]][i]
    unit <- x[[paste0("unit_", lang)]][i]
    note <- x[[paste0("note_", lang)]][i]

    cat("**", pdf_txt(x$period[i]), " | ", pdf_txt(degree), " - ", pdf_txt(field), "**  \n", sep = "")
    cat(pdf_txt(x$institution[i]), " - ", pdf_txt(unit), "  \n", sep = "")

    if (nzchar(pdf_txt(x$thesis[i]))) {
      label <- if (lang == "tr") "Tez" else "Thesis"
      cat("**", label, ":** *", pdf_txt(x$thesis[i]), "*  \n", sep = "")
    }

    if (nzchar(pdf_txt(x$advisor[i]))) {
      label <- if (lang == "tr") "Danışman" else "Advisor"
      cat("**", label, ":** ", pdf_txt(x$advisor[i]), "  \n", sep = "")
    }

    if (nzchar(pdf_txt(note))) cat(pdf_txt(note), "  \n")
    cat("\n")
  }
}

pdf_projects <- function(x, lang = "tr") {
  x <- x[order(x$display_order), , drop = FALSE]
  for (i in seq_len(nrow(x))) {
    title <- x[[paste0("title_", lang)]][i]
    funding <- x[[paste0("funding_", lang)]][i]
    role <- x[[paste0("role_", lang)]][i]
    date <- x[[paste0("date_", lang)]][i]
    role_label <- if (lang == "tr") "Rol" else "Role"

    cat("**", pdf_txt(title), "**  \n", sep = "")
    cat(pdf_txt(funding), "  \n")
    cat("**", role_label, ":** ", pdf_txt(role), " | ", pdf_txt(date), "\n\n", sep = "")
  }
}

pdf_teaching <- function(x, lang = "tr") {
  x <- x[order(x$order), , drop = FALSE]
  field <- paste0("course_", lang)
  for (i in seq_len(nrow(x))) {
    cat("- ", pdf_txt(x[[field]][i]), "\n", sep = "")
  }
}

pdf_publications <- function(x, category, lang = "tr") {

  if (category == "books") {
    d <- x[x$category %in% c("book", "book_chapter"), , drop = FALSE]
  } else {
    d <- x[x$category == category, , drop = FALSE]
  }

  d <- d[order(d$display_order), , drop = FALSE]

  for (i in seq_len(nrow(d))) {

    authors <- pdf_authors(d$authors[i])
    year <- pdf_txt(d$year[i])
    title <- pdf_txt(d$title[i])
    venue <- pdf_txt(d$venue[i])
    volume <- pdf_txt(d$volume_issue[i])
    pages <- pdf_txt(d$pages[i])
    doi <- pdf_txt(d$doi[i])
    status <- pdf_txt(d$status[i])

    if (category == "under_review") {
      cat("- ")
      if (nzchar(authors)) cat(authors, " ")
      cat("**", title, ".** ", sep = "")

      if (status == "peer_review") {
        label <- if (lang == "tr") "Hakem değerlendirmesinde" else "In peer review"
        cat(label, ": *", venue, ".*\n", sep = "")
      } else if (status == "revising") {
        label <- if (lang == "tr") "Revizyon / yeniden gönderim hazırlığı" else "Revision / preparing resubmission"
        cat(label, ".\n", sep = "")
      } else {
        label <- if (lang == "tr") "Gönderildi / editoryal süreçte" else "Submitted / in editorial process"
        if (nzchar(venue)) {
          cat(label, ": *", venue, ".*\n", sep = "")
        } else {
          cat(label, ".\n", sep = "")
        }
      }

    } else if (category == "books") {

      contribution <- if (lang == "tr") d$contribution_tr[i] else d$contribution_en[i]

      cat("- ")
      if (nzchar(year)) cat("(", year, "). ", sep = "")
      cat("**", title, ".** ", venue, sep = "")
      if (nzchar(pdf_txt(contribution))) cat(". ", pdf_txt(contribution), sep = "")
      cat(".\n")

    } else {

      cat("- ", authors, sep = "")
      if (nzchar(year)) cat(" (", year, ")", sep = "")
      cat(". **", title, ".** *", venue, "*", sep = "")
      if (nzchar(volume)) cat(", ", volume, sep = "")
      if (nzchar(pages)) cat(", ", pages, sep = "")
      cat(".", sep = "")
      if (nzchar(doi)) cat(" https://doi.org/", doi, sep = "")
      cat("\n")
    }
  }
}

pdf_networks <- function(x) {
  x <- x[order(x$order), , drop = FALSE]
  for (i in seq_len(nrow(x))) {
    cat("- **", pdf_txt(x$short_name[i]), " - ", pdf_txt(x$code[i]), "**: ",
        pdf_txt(x$title[i]), ". ", pdf_txt(x$groups[i]), "\n", sep = "")
  }
}

pdf_conferences <- function(x, type) {
  d <- x[x$type == type, , drop = FALSE]
  d <- d[order(-d$year, d$order), , drop = FALSE]
  for (i in seq_len(nrow(d))) {
    cat("- ", pdf_txt(d$authors[i]), " (", d$year[i], "). **",
        pdf_txt(d$title[i]), ".** ", pdf_txt(d$event[i]), ".\n", sep = "")
  }
}

pdf_professional <- function(x, section, lang = "tr") {
  d <- x[x$section == section, , drop = FALSE]
  d <- d[order(d$order), , drop = FALSE]
  title_field <- paste0("title_", lang)
  detail_field <- paste0("detail_", lang)

  for (i in seq_len(nrow(d))) {
    cat("- **", pdf_txt(d[[title_field]][i]), "**", sep = "")
    if (nzchar(pdf_txt(d$period[i]))) cat(" (", pdf_txt(d$period[i]), ")", sep = "")
    if (nzchar(pdf_txt(d[[detail_field]][i]))) cat(": ", pdf_txt(d[[detail_field]][i]), sep = "")
    cat("\n")
  }
}
