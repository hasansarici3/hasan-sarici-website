site_dir <- normalizePath(getwd(), mustWork = TRUE)
pdf_dir <- file.path(site_dir, "_pdf")
docs_dir <- file.path(site_dir, "assets", "documents")

dir.create(docs_dir, recursive = TRUE, showWarnings = FALSE)

build_one_pdf <- function(source, output_name) {

  quarto::quarto_render(
    input = file.path(pdf_dir, source),
    output_format = "typst",
    output_file = output_name,
    execute_dir = site_dir,
    as_job = FALSE
  )

  generated <- file.path(
    pdf_dir,
    paste0(output_name, ".pdf")
  )

  if (!file.exists(generated)) {
    stop("PDF oluşturulamadı: ", generated)
  }

  destination <- file.path(
    docs_dir,
    basename(generated)
  )

  file.copy(
    generated,
    destination,
    overwrite = TRUE
  )

  message("PDF hazır: ", destination)
}

build_one_pdf(
  "cv-tr.qmd",
  "Hasan_Sarici_Akademik_CV_TR"
)

build_one_pdf(
  "cv-en.qmd",
  "Hasan_Sarici_Academic_CV_EN"
)

babelquarto::render_website(
  project_path = site_dir,
  preview = FALSE
)

message("PDF CVler ve web sitesi başarıyla güncellendi.")
