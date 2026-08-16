# Hasan Sarıcı Academic Website — one-click content update
#
# Normal use:
#   1. Edit and save Dropbox/Hasan_Sarici_Website/website_content.xlsx
#   2. Open this repository in RStudio.
#   3. Open UPDATE_WEBSITE.R and click Source.
#   4. Review the detected changes and type EVET when asked to publish.
#
# The script deliberately keeps Dropbox and Git responsibilities separate:
# - Dropbox workbook = human-facing content manager
# - data/*.csv         = version-controlled build inputs
# - GitHub             = source history and deployment trigger
#
# It refuses to run on a dirty Git working tree, pulls main with --ff-only,
# validates the workbook, creates a Dropbox backup, regenerates CSV files,
# builds and validates the complete site, asks for explicit confirmation,
# then commits/pushes only the managed content and generated CV PDFs.

options(stringsAsFactors = FALSE)

update_website <- function() {
  cat("\n============================================================\n")
  cat(" Hasan Sarıcı Academic Website — Dropbox Update\n")
  cat("============================================================\n\n")

  # ---------- Helpers ----------
  command_output <- function(command, args = character(), check = TRUE) {
    out <- suppressWarnings(
      system2(command, args = args, stdout = TRUE, stderr = TRUE)
    )
    status <- attr(out, "status")
    if (is.null(status)) status <- 0L

    if (check && status != 0L) {
      stop(
        paste0(
          "Komut başarısız oldu (", command, ", exit ", status, ").\n",
          paste(out, collapse = "\n")
        ),
        call. = FALSE
      )
    }

    attr(out, "status") <- status
    out
  }

  site_dir <- if (file.exists(file.path(getwd(), "build_site.R"))) {
    normalizePath(getwd(), mustWork = TRUE)
  } else {
    candidate <- path.expand("~/Documents/hasan-sarici-website")
    if (!file.exists(file.path(candidate, "build_site.R"))) {
      stop(
        paste0(
          "Site repository'si bulunamadı. RStudio'da hasan-sarici-website ",
          "projesini açıp UPDATE_WEBSITE.R dosyasını tekrar Source edin."
        ),
        call. = FALSE
      )
    }
    normalizePath(candidate, mustWork = TRUE)
  }

  git <- function(args, check = TRUE) {
    command_output(
      "git",
      c("-C", shQuote(site_dir), args),
      check = check
    )
  }

  ensure_package <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      message("Gerekli R paketi kuruluyor: ", pkg)
      install.packages(pkg, repos = "https://cloud.r-project.org")
    }
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("R paketi kurulamadı: ", pkg, call. = FALSE)
    }
  }

  locate_workbook <- function() {
    configured <- Sys.getenv("HASAN_SITE_CONTENT_XLSX", unset = "")

    candidates <- c(
      configured,
      file.path(
        path.expand("~/Library/CloudStorage/Dropbox"),
        "Hasan_Sarici_Website",
        "website_content.xlsx"
      ),
      file.path(
        path.expand("~/Library/CloudStorage/Dropbox-Personal"),
        "Hasan_Sarici_Website",
        "website_content.xlsx"
      ),
      file.path(
        path.expand("~/Dropbox"),
        "Hasan_Sarici_Website",
        "website_content.xlsx"
      )
    )

    cloud_root <- path.expand("~/Library/CloudStorage")
    if (dir.exists(cloud_root)) {
      cloud_dirs <- list.dirs(cloud_root, recursive = FALSE, full.names = TRUE)
      dropbox_dirs <- cloud_dirs[
        grepl("^Dropbox", basename(cloud_dirs), ignore.case = TRUE)
      ]
      candidates <- c(
        candidates,
        file.path(
          dropbox_dirs,
          "Hasan_Sarici_Website",
          "website_content.xlsx"
        )
      )
    }

    candidates <- unique(candidates[nzchar(candidates)])
    found <- candidates[file.exists(candidates)]

    if (!length(found)) {
      stop(
        paste0(
          "Dropbox yönetim dosyası Mac'te bulunamadı.\n",
          "Beklenen dosya: Hasan_Sarici_Website/website_content.xlsx\n",
          "Dropbox masaüstü uygulamasının dosyayı Mac'e senkronize ettiğini kontrol edin.\n",
          "Gerekirse RStudio'da şu ortam değişkenini tanımlayabilirsiniz:\n",
          "Sys.setenv(HASAN_SITE_CONTENT_XLSX = '/tam/yol/website_content.xlsx')"
        ),
        call. = FALSE
      )
    }

    normalizePath(found[[1]], mustWork = TRUE)
  }

  clean_text <- function(x) {
    x <- as.character(x)
    x[is.na(x)] <- ""
    trimws(x)
  }

  as_integer_column <- function(x, sheet, column) {
    x <- clean_text(x)
    out <- rep(NA_integer_, length(x))
    keep <- nzchar(x)
    parsed <- suppressWarnings(as.integer(x[keep]))
    if (any(is.na(parsed))) {
      bad <- unique(x[keep][is.na(parsed)])
      stop(
        sheet, " / ", column,
        " sütununda tam sayı olmayan değer var: ",
        paste(bad, collapse = ", "),
        call. = FALSE
      )
    }
    out[keep] <- parsed
    out
  }

  as_logical_column <- function(x, sheet, column) {
    x <- toupper(clean_text(x))
    allowed <- c("TRUE", "FALSE")
    bad <- unique(x[nzchar(x) & !x %in% allowed])
    if (length(bad)) {
      stop(
        sheet, " / ", column,
        " yalnızca TRUE veya FALSE içerebilir. Hatalı: ",
        paste(bad, collapse = ", "),
        call. = FALSE
      )
    }
    out <- rep(NA, length(x))
    out[x == "TRUE"] <- TRUE
    out[x == "FALSE"] <- FALSE
    out
  }

  require_nonempty <- function(df, columns, sheet) {
    for (column in columns) {
      empty <- !nzchar(clean_text(df[[column]]))
      if (any(empty)) {
        stop(
          sheet, " / ", column,
          " sütununda boş bırakılmaması gereken satır(lar) var: ",
          paste(which(empty) + 1L, collapse = ", "),
          call. = FALSE
        )
      }
    }
  }

  require_unique <- function(df, column, sheet) {
    values <- clean_text(df[[column]])
    values <- values[nzchar(values)]
    dup <- unique(values[duplicated(values)])
    if (length(dup)) {
      stop(
        sheet, " / ", column,
        " sütununda yinelenen değer var: ",
        paste(dup, collapse = ", "),
        call. = FALSE
      )
    }
  }

  # ---------- Pre-flight Git safety ----------
  if (!nzchar(Sys.which("git"))) {
    stop("Git bulunamadı.", call. = FALSE)
  }

  status_before <- git(c("status", "--porcelain"), check = TRUE)
  status_before <- status_before[nzchar(status_before)]
  if (length(status_before)) {
    cat("Yerel repository temiz değil:\n")
    cat(paste0("  ", status_before, "\n"))
    stop(
      paste0(
        "Güvenlik nedeniyle işlem durduruldu. Mevcut yerel değişiklikleri ",
        "kaybetmemek için önce bunları inceleyin/commit edin."
      ),
      call. = FALSE
    )
  }

  message("1/8 GitHub ile güvenli eşitleme...")
  pull_output <- git(c("pull", "--ff-only", "origin", "main"), check = TRUE)
  if (length(pull_output)) message(paste(pull_output, collapse = "\n"))

  workbook <- locate_workbook()
  dropbox_root <- dirname(workbook)
  backup_dir <- file.path(dropbox_root, "backups")
  cv_dir <- file.path(dropbox_root, "cv")
  dir.create(backup_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(cv_dir, recursive = TRUE, showWarnings = FALSE)

  message("2/8 Dropbox Excel dosyası bulundu: ", workbook)
  ensure_package("readxl")

  # ---------- Workbook contract ----------
  sheet_map <- c(
    Profile = "profile.csv",
    Research = "research_interests.csv",
    Education = "education.csv",
    Experience = "experience.csv",
    Teaching = "teaching.csv",
    Publications = "publications.csv",
    Projects = "projects.csv",
    Networks = "networks.csv",
    Professional = "professional.csv",
    Conferences = "conferences.csv"
  )

  expected_columns <- list(
    Profile = c(
      "name", "position_tr", "position_en", "department_tr", "department_en",
      "faculty_tr", "faculty_en", "institution_tr", "institution_en", "email",
      "orcid", "program_tr", "program_en"
    ),
    Research = c("order", "label_tr", "label_en"),
    Education = c(
      "order", "period", "degree_tr", "degree_en", "field_tr", "field_en",
      "institution_tr", "institution_en", "unit_en", "unit_tr", "thesis",
      "advisor", "note_tr", "note_en"
    ),
    Experience = c(
      "order", "period_tr", "period_en", "position_tr", "position_en",
      "institution_tr", "institution_en", "unit_tr", "unit_en"
    ),
    Teaching = c(
      "order", "period", "course_tr", "course_en", "language_tr", "language_en"
    ),
    Publications = c(
      "id", "year", "status", "category", "scope", "authors", "title",
      "venue", "volume_issue", "pages", "doi", "contribution_tr",
      "contribution_en", "display_order"
    ),
    Projects = c(
      "id", "status", "start_year", "end_year", "date_tr", "date_en",
      "title_tr", "title_en", "funding_tr", "funding_en", "role_tr",
      "role_en", "area_tr", "area_en", "external_funding", "display_order"
    ),
    Networks = c("order", "code", "short_name", "title", "groups", "period"),
    Professional = c(
      "order", "section", "period", "title_tr", "title_en", "detail_tr", "detail_en"
    ),
    Conferences = c("order", "type", "year", "authors", "title", "event")
  )

  actual_sheets <- readxl::excel_sheets(workbook)
  missing_sheets <- setdiff(names(sheet_map), actual_sheets)
  if (length(missing_sheets)) {
    stop(
      "Excel dosyasında zorunlu sekmeler eksik: ",
      paste(missing_sheets, collapse = ", "),
      call. = FALSE
    )
  }

  message("3/8 Excel yapısı ve içerik kuralları doğrulanıyor...")

  imported <- list()
  for (sheet in names(sheet_map)) {
    df <- as.data.frame(
      readxl::read_excel(
        workbook,
        sheet = sheet,
        col_types = "text",
        .name_repair = "minimal"
      ),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )

    if (!identical(names(df), expected_columns[[sheet]])) {
      stop(
        paste0(
          sheet, " sekmesinin sütunları değişmiş.\nBeklenen: ",
          paste(expected_columns[[sheet]], collapse = " | "),
          "\nBulunan: ", paste(names(df), collapse = " | "),
          "\nSütun adlarını/sırasını değiştirmeyin."
        ),
        call. = FALSE
      )
    }

    if (nrow(df)) {
      keep <- apply(
        df,
        1,
        function(row) any(nzchar(trimws(ifelse(is.na(row), "", as.character(row)))))
      )
      df <- df[keep, , drop = FALSE]
    }

    if (!nrow(df)) {
      stop(sheet, " sekmesi tamamen boş olamaz.", call. = FALSE)
    }

    for (column in names(df)) {
      df[[column]] <- clean_text(df[[column]])
    }

    integer_columns <- intersect(
      c("order", "year", "start_year", "end_year", "display_order"),
      names(df)
    )
    for (column in integer_columns) {
      df[[column]] <- as_integer_column(df[[column]], sheet, column)
    }

    if ("external_funding" %in% names(df)) {
      df$external_funding <- as_logical_column(
        df$external_funding,
        sheet,
        "external_funding"
      )
    }

    imported[[sheet]] <- df
  }

  # Generic ordering/identity checks.
  for (sheet in names(imported)) {
    df <- imported[[sheet]]
    if ("order" %in% names(df)) {
      if (any(is.na(df$order)) || any(df$order < 1L) || anyDuplicated(df$order)) {
        stop(sheet, " / order pozitif ve benzersiz tam sayılar olmalıdır.", call. = FALSE)
      }
    }
    if ("display_order" %in% names(df)) {
      if (
        any(is.na(df$display_order)) ||
        any(df$display_order < 1L) ||
        anyDuplicated(df$display_order)
      ) {
        stop(
          sheet,
          " / display_order pozitif ve benzersiz tam sayılar olmalıdır.",
          call. = FALSE
        )
      }
    }
  }

  # Profile.
  if (nrow(imported$Profile) != 1L) {
    stop("Profile sekmesinde tam olarak 1 veri satırı olmalıdır.", call. = FALSE)
  }
  require_nonempty(
    imported$Profile,
    c(
      "name", "position_tr", "position_en", "department_tr", "department_en",
      "faculty_tr", "faculty_en", "institution_tr", "institution_en", "email",
      "orcid", "program_tr", "program_en"
    ),
    "Profile"
  )

  # Publications.
  p <- imported$Publications
  require_nonempty(p, c("id", "status", "category", "title"), "Publications")
  require_unique(p, "id", "Publications")
  bad_id <- p$id[!grepl("^PUB[0-9]{3,}$", p$id)]
  if (length(bad_id)) {
    stop("Geçersiz yayın ID: ", paste(unique(bad_id), collapse = ", "), call. = FALSE)
  }

  allowed_status <- c("published", "submitted", "peer_review", "revising")
  allowed_category <- c("peer_reviewed", "under_review", "book", "book_chapter")
  allowed_scope <- c("", "national", "international")

  bad <- setdiff(unique(p$status), allowed_status)
  if (length(bad)) stop("Geçersiz publication status: ", paste(bad, collapse = ", "), call. = FALSE)
  bad <- setdiff(unique(p$category), allowed_category)
  if (length(bad)) stop("Geçersiz publication category: ", paste(bad, collapse = ", "), call. = FALSE)
  bad <- setdiff(unique(p$scope), allowed_scope)
  if (length(bad)) stop("Geçersiz publication scope: ", paste(bad, collapse = ", "), call. = FALSE)

  pipeline <- p$status %in% c("submitted", "peer_review", "revising")
  if (any(pipeline & p$category != "under_review")) {
    stop(
      "submitted / peer_review / revising statüsündeki kayıtların category değeri under_review olmalıdır.",
      call. = FALSE
    )
  }
  if (any(p$status == "published" & p$category == "under_review")) {
    stop("published bir kayıt under_review kategorisinde olamaz.", call. = FALSE)
  }
  if (any(p$status == "published" & is.na(p$year))) {
    stop("published kayıtların year alanı boş olamaz.", call. = FALSE)
  }
  doi <- p$doi[nzchar(p$doi)]
  if (length(doi) && any(!grepl("^10\\.", doi))) {
    stop("DOI alanı 10. ile başlamalıdır: ", paste(doi[!grepl("^10\\.", doi)], collapse = ", "), call. = FALSE)
  }

  # Projects.
  pr <- imported$Projects
  require_nonempty(pr, c("id", "status", "title_tr", "title_en"), "Projects")
  require_unique(pr, "id", "Projects")
  bad_id <- pr$id[!grepl("^PROJ[0-9]{3,}$", pr$id)]
  if (length(bad_id)) {
    stop("Geçersiz proje ID: ", paste(unique(bad_id), collapse = ", "), call. = FALSE)
  }
  bad <- setdiff(unique(pr$status), c("ongoing", "completed"))
  if (length(bad)) stop("Geçersiz project status: ", paste(bad, collapse = ", "), call. = FALSE)
  if (any(is.na(pr$start_year))) {
    stop("Projects / start_year boş olamaz.", call. = FALSE)
  }

  # Other controlled fields.
  bad <- setdiff(unique(imported$Professional$section), c(
    "certification", "coaching", "membership", "language", "skill"
  ))
  if (length(bad)) stop("Geçersiz Professional section: ", paste(bad, collapse = ", "), call. = FALSE)

  bad <- setdiff(unique(imported$Conferences$type), c("international", "national"))
  if (length(bad)) stop("Geçersiz Conferences type: ", paste(bad, collapse = ", "), call. = FALSE)

  # Destructive-edit guard: prevent an accidental large deletion from a sheet.
  for (sheet in names(sheet_map)) {
    current_path <- file.path(site_dir, "data", unname(sheet_map[[sheet]]))
    if (file.exists(current_path)) {
      old <- read.csv(
        current_path,
        stringsAsFactors = FALSE,
        check.names = FALSE,
        fileEncoding = "UTF-8"
      )
      old_n <- nrow(old)
      new_n <- nrow(imported[[sheet]])
      if (old_n >= 4L && new_n < floor(old_n * 0.60)) {
        stop(
          paste0(
            sheet, " sekmesinde çok büyük satır kaybı algılandı (",
            old_n, " -> ", new_n, "). Güvenlik nedeniyle işlem durduruldu."
          ),
          call. = FALSE
        )
      }
    }
  }

  timestamp <- format(Sys.time(), "%Y-%m-%d_%H%M%S")
  workbook_backup <- file.path(
    backup_dir,
    paste0("website_content_", timestamp, ".xlsx")
  )
  if (!file.copy(workbook, workbook_backup, overwrite = FALSE)) {
    stop("Dropbox Excel yedeği oluşturulamadı: ", workbook_backup, call. = FALSE)
  }
  message("Excel yedeği: ", workbook_backup)

  rollback_needed <- FALSE
  completed <- FALSE
  on.exit({
    if (rollback_needed && !completed) {
      message("İşlem tamamlanmadığı için repository kaynakları geri yükleniyor...")
      git(c("restore", "--", "data", "assets/documents"), check = FALSE)
    }
  }, add = TRUE)

  # ---------- Generate CSV build inputs ----------
  message("4/8 Excel -> data/*.csv aktarımı...")
  for (sheet in names(sheet_map)) {
    destination <- file.path(site_dir, "data", unname(sheet_map[[sheet]]))
    write.csv(
      imported[[sheet]],
      destination,
      row.names = FALSE,
      na = "",
      fileEncoding = "UTF-8",
      qmethod = "double"
    )
  }
  rollback_needed <- TRUE

  data_changes <- git(c("status", "--porcelain", "--", "data"), check = TRUE)
  data_changes <- data_changes[nzchar(data_changes)]
  if (!length(data_changes)) {
    completed <- TRUE
    rollback_needed <- FALSE
    cat("\nExcel ile GitHub verileri zaten aynı. Yayınlanacak içerik değişikliği yok.\n")
    cat("Excel yedeği oluşturuldu: ", workbook_backup, "\n", sep = "")
    return(invisible(TRUE))
  }

  # ---------- Build and validate ----------
  message("5/8 PDF CV'ler ve iki dilli site oluşturuluyor...")
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(site_dir)
  source("build_site.R", chdir = TRUE)

  message("6/8 Yerel site validator çalıştırılıyor...")
  validator <- file.path(site_dir, "scripts", "validate_site.py")
  validation <- command_output(
    "python3",
    c(shQuote(validator), shQuote(file.path(site_dir, "_site"))),
    check = TRUE
  )
  if (length(validation)) message(paste(validation, collapse = "\n"))

  # Only expected content/PDF files may have changed in a clean repository.
  changed <- git(c("status", "--short"), check = TRUE)
  changed <- changed[nzchar(changed)]
  allowed <- grepl("^[ MARC?D]{2} (data/|assets/documents/)", changed)
  if (length(changed) && any(!allowed)) {
    cat("Beklenmeyen değişiklikler:\n")
    cat(paste0("  ", changed[!allowed], "\n"))
    stop(
      "Otomatik güncelleme beklenmeyen dosyalara dokunduğu için işlem durduruldu.",
      call. = FALSE
    )
  }

  cat("\n--- Yayınlanacak değişiklikler ---\n")
  cat(paste0(changed, "\n"))
  diff_stat <- git(c("diff", "--stat"), check = TRUE)
  if (length(diff_stat)) cat(paste0(diff_stat, "\n"))

  if (!interactive()) {
    stop(
      "Yayınlama onayı interaktif RStudio oturumu gerektirir. UPDATE_WEBSITE.R dosyasını RStudio'da Source edin.",
      call. = FALSE
    )
  }

  answer <- readline(
    paste0(
      "\nBu değişiklikleri GitHub'a gönderip siteyi güncellemek için EVET yazın: "
    )
  )

  if (toupper(trimws(answer)) != "EVET") {
    git(c("restore", "--", "data", "assets/documents"), check = FALSE)
    rollback_needed <- FALSE
    completed <- TRUE
    cat("\nYayınlama iptal edildi. Git repository tekrar temiz duruma getirildi.\n")
    cat("Dropbox Excel'indeki düzenlemeleriniz korunuyor; istediğiniz zaman yeniden Source edebilirsiniz.\n")
    return(invisible(FALSE))
  }

  # ---------- Commit and push ----------
  message("7/8 Git commit ve push...")
  git(c("add", "--", "data", "assets/documents"), check = TRUE)

  commit_output <- git(
    c("commit", "-m", shQuote("Update academic website from Dropbox workbook")),
    check = TRUE
  )
  if (length(commit_output)) message(paste(commit_output, collapse = "\n"))

  push_output <- git(c("push", "origin", "main"), check = TRUE)
  if (length(push_output)) message(paste(push_output, collapse = "\n"))

  # ---------- External recovery copy ----------
  message("8/8 Dropbox CV kopyaları ve Git bundle yedeği...")

  pdf_files <- c(
    "Hasan_Sarici_Akademik_CV_TR.pdf",
    "Hasan_Sarici_Academic_CV_EN.pdf"
  )
  for (pdf in pdf_files) {
    source_pdf <- file.path(site_dir, "assets", "documents", pdf)
    destination_pdf <- file.path(cv_dir, pdf)
    if (!file.copy(source_pdf, destination_pdf, overwrite = TRUE)) {
      warning("CV Dropbox'a kopyalanamadı: ", destination_pdf, call. = FALSE)
    }
  }

  bundle_file <- file.path(
    backup_dir,
    paste0("hasan-sarici-website_", timestamp, ".bundle")
  )
  bundle_output <- git(
    c("bundle", "create", shQuote(bundle_file), "--all"),
    check = TRUE
  )
  if (length(bundle_output)) message(paste(bundle_output, collapse = "\n"))

  verify_output <- git(
    c("bundle", "verify", shQuote(bundle_file)),
    check = TRUE
  )
  if (length(verify_output)) message(paste(verify_output, collapse = "\n"))

  rollback_needed <- FALSE
  completed <- TRUE

  cat("\n============================================================\n")
  cat(" GÜNCELLEME GITHUB'A GÖNDERİLDİ\n")
  cat("============================================================\n")
  cat("Dropbox Excel yedeği : ", workbook_backup, "\n", sep = "")
  cat("Git bundle yedeği    : ", bundle_file, "\n", sep = "")
  cat("CV klasörü           : ", cv_dir, "\n", sep = "")
  cat("GitHub Actions        : https://github.com/hasansarici3/hasan-sarici-website/actions\n")
  cat("Canlı site            : https://hasansarici.com/\n\n")
  cat("GitHub Actions deploy'u tamamlanınca canlı site yeni içeriğe geçer.\n")

  invisible(TRUE)
}

update_website()
