cv_read <- function(path) {
  read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    fileEncoding = "UTF-8",
    na.strings = c("", "NA")
  )
}

cv_clean <- function(x) {
  if (length(x) == 0 || is.na(x)) return("")
  trimws(as.character(x))
}

cv_escape <- function(x) {
  x <- cv_clean(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

load_cv_data <- function() {
  list(
    profile = cv_read("data/profile.csv"),
    interests = cv_read("data/research_interests.csv"),
    education = cv_read("data/education.csv"),
    experience = cv_read("data/experience.csv"),
    teaching = cv_read("data/teaching.csv"),
    networks = cv_read("data/networks.csv"),
    professional = cv_read("data/professional.csv"),
    publications = cv_read("data/publications.csv"),
    projects = cv_read("data/projects.csv")
  )
}

render_cv_interests <- function(x, lang = "tr") {
  field <- paste0("label_", lang)
  x <- x[order(x$order), , drop = FALSE]
  cat('<div class="cv-chip-grid">\n')
  for (i in seq_len(nrow(x))) {
    cat('<span class="cv-chip">', cv_escape(x[[field]][i]), '</span>\n', sep = "")
  }
  cat("</div>\n")
}

render_cv_experience <- function(x, lang = "tr") {
  x <- x[order(x$order), , drop = FALSE]
  for (i in seq_len(nrow(x))) {
    period <- x[[paste0("period_", lang)]][i]
    position <- x[[paste0("position_", lang)]][i]
    institution <- x[[paste0("institution_", lang)]][i]
    unit <- x[[paste0("unit_", lang)]][i]

    cat('<div class="cv-timeline-item">\n')
    cat('<div class="cv-period">', cv_escape(period), '</div>\n', sep = "")
    cat('<div class="cv-timeline-content">\n')
    cat("<h3>", cv_escape(position), "</h3>\n", sep = "")
    cat("<p><strong>", cv_escape(institution), "</strong><br>", cv_escape(unit), "</p>\n", sep = "")
    cat("</div></div>\n")
  }
}

render_cv_education <- function(x, lang = "tr") {
  x <- x[order(x$order), , drop = FALSE]
  for (i in seq_len(nrow(x))) {

    degree <- x[[paste0("degree_", lang)]][i]
    field <- x[[paste0("field_", lang)]][i]
    institution <- x[[paste0("institution_", lang)]][i]
    unit <- x[[paste0("unit_", lang)]][i]
    note <- x[[paste0("note_", lang)]][i]

    cat('<div class="cv-timeline-item">\n')
    cat('<div class="cv-period">', cv_escape(x$period[i]), '</div>\n', sep = "")
    cat('<div class="cv-timeline-content">\n')
    cat("<h3>", cv_escape(degree), " · ", cv_escape(field), "</h3>\n", sep = "")
    cat("<p><strong>", cv_escape(institution), "</strong><br>", cv_escape(unit), "</p>\n", sep = "")

    if (nzchar(cv_clean(x$thesis[i]))) {
      thesis_label <- if (lang == "tr") "Tez" else "Thesis"
      cat("<p><strong>", thesis_label, ":</strong> <em>", cv_escape(x$thesis[i]), "</em></p>\n", sep = "")
    }

    if (nzchar(cv_clean(x$advisor[i]))) {
      advisor_label <- if (lang == "tr") "Danışman" else "Advisor"
      cat("<p><strong>", advisor_label, ":</strong> ", cv_escape(x$advisor[i]), "</p>\n", sep = "")
    }

    if (nzchar(cv_clean(note))) {
      cat('<p class="cv-muted">', cv_escape(note), "</p>\n", sep = "")
    }

    cat("</div></div>\n")
  }
}

render_cv_teaching <- function(x, lang = "tr") {
  field <- paste0("course_", lang)
  x <- x[order(x$order), , drop = FALSE]
  cat('<div class="cv-list-grid">\n')
  for (i in seq_len(nrow(x))) {
    cat('<div class="cv-list-item">', cv_escape(x[[field]][i]), "</div>\n", sep = "")
  }
  cat("</div>\n")
}

render_cv_projects <- function(x, lang = "tr") {
  x <- x[order(x$display_order), , drop = FALSE]
  for (i in seq_len(nrow(x))) {

    title <- x[[paste0("title_", lang)]][i]
    funding <- x[[paste0("funding_", lang)]][i]
    role <- x[[paste0("role_", lang)]][i]
    date <- x[[paste0("date_", lang)]][i]

    cat('<div class="cv-project-item">\n')
    cat("<h3>", cv_escape(title), "</h3>\n", sep = "")
    cat('<p class="cv-muted">', cv_escape(funding), "</p>\n", sep = "")

    role_label <- if (lang == "tr") "Rol" else "Role"
    cat("<p><strong>", role_label, ":</strong> ", cv_escape(role), " · ", cv_escape(date), "</p>\n", sep = "")
    cat("</div>\n")
  }
}

render_cv_publications <- function(x, category, lang = "tr") {

  if (category == "books") {
    d <- x[x$category %in% c("book", "book_chapter"), , drop = FALSE]
  } else {
    d <- x[x$category == category, , drop = FALSE]
  }

  if ("display_order" %in% names(d)) {
    d <- d[order(d$display_order), , drop = FALSE]
  }

  for (i in seq_len(nrow(d))) {

    year <- cv_clean(d$year[i])
    authors <- cv_clean(d$authors[i])
    title <- cv_clean(d$title[i])
    venue <- cv_clean(d$venue[i])
    volume <- cv_clean(d$volume_issue[i])
    pages <- cv_clean(d$pages[i])
    doi <- cv_clean(d$doi[i])
    status <- cv_clean(d$status[i])

    cat('<div class="cv-publication-item">\n')

    if (nzchar(year)) {
      cat('<div class="cv-publication-year">', cv_escape(year), "</div>\n", sep = "")
    }

    cat('<div class="cv-publication-body">\n')
    cat("<h3>", cv_escape(title), "</h3>\n", sep = "")

    if (nzchar(authors)) {
      cat("<p>", cv_escape(authors), "</p>\n", sep = "")
    }

    if (category == "under_review") {
      if (status == "peer_review") {
        status_label <- if (lang == "tr") "Hakem değerlendirmesinde" else "In peer review"
        cat('<p class="cv-muted"><strong>', status_label, ':</strong> ', cv_escape(venue), "</p>\n", sep = "")
      } else if (status == "revising") {
        status_label <- if (lang == "tr") "Durum" else "Status"
        status_value <- if (lang == "tr") "Revizyon / yeniden gönderim hazırlığı" else "Revision / preparing resubmission"
        cat('<p class="cv-muted"><strong>', status_label, ':</strong> ', status_value, "</p>\n", sep = "")
      } else {
        status_label <- if (lang == "tr") "Gönderildi / editoryal süreçte" else "Submitted / in editorial process"
        if (nzchar(venue)) {
          cat('<p class="cv-muted"><strong>', status_label, ':</strong> ', cv_escape(venue), "</p>\n", sep = "")
        } else {
          cat('<p class="cv-muted"><strong>', status_label, "</strong></p>\n", sep = "")
        }
      }
    } else {

      meta <- venue
      if (nzchar(volume)) meta <- paste(meta, volume, sep = ", ")
      if (nzchar(pages)) meta <- paste(meta, pages, sep = ", ")

      cat('<p class="cv-muted">', cv_escape(meta), "</p>\n", sep = "")

      if (nzchar(doi)) {
        cat('<p><a href="https://doi.org/', cv_escape(doi), '" target="_blank">DOI</a></p>\n', sep = "")
      }
    }

    cat("</div></div>\n")
  }
}

render_cv_networks <- function(x) {
  x <- x[order(x$order), , drop = FALSE]
  for (i in seq_len(nrow(x))) {
    cat('<div class="cv-network-item">\n')
    cat("<h3>", cv_escape(x$short_name[i]), " · ", cv_escape(x$code[i]), "</h3>\n", sep = "")
    cat("<p><strong>", cv_escape(x$title[i]), "</strong></p>\n", sep = "")
    cat('<p class="cv-muted">', cv_escape(x$groups[i]), "</p>\n", sep = "")
    cat("</div>\n")
  }
}

render_cv_professional <- function(x, section, lang = "tr") {

  d <- x[x$section == section, , drop = FALSE]
  d <- d[order(d$order), , drop = FALSE]

  title_field <- paste0("title_", lang)
  detail_field <- paste0("detail_", lang)

  cat('<div class="cv-professional-grid">\n')

  for (i in seq_len(nrow(d))) {

    cat('<div class="cv-professional-item">\n')

    if (nzchar(cv_clean(d$period[i]))) {
      cat('<div class="cv-small-label">', cv_escape(d$period[i]), "</div>\n", sep = "")
    }

    cat("<strong>", cv_escape(d[[title_field]][i]), "</strong>\n", sep = "")

    if (nzchar(cv_clean(d[[detail_field]][i]))) {
      cat('<div class="cv-muted">', cv_escape(d[[detail_field]][i]), "</div>\n", sep = "")
    }

    cat("</div>\n")
  }

  cat("</div>\n")
}
