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

# babelquarto currently leaves the source-language suffix in English
# hreflang URLs (e.g. /en/about.en.html) even though the deployed file is
# /en/about.html. Repair only the generated alternate-language metadata.
site_output <- file.path(site_dir, "_site")
html_files <- list.files(
  site_output,
  pattern = "\\.html$",
  recursive = TRUE,
  full.names = TRUE
)

for (html_file in html_files) {
  x <- readLines(html_file, warn = FALSE, encoding = "UTF-8")
  target <- grepl('rel="alternate"', x, fixed = TRUE) &
    grepl('hreflang="en"', x, fixed = TRUE)

  if (any(target)) {
    x[target] <- sub("\\.en\\.html", ".html", x[target])
    writeLines(x, html_file, useBytes = TRUE)
  }
}

# Normalize canonical and hreflang URLs to the production domain.
# babelquarto may emit root-relative URLs such as /about.html or /en/about.html.
base_url <- "https://hasansarici.com"

for (html_file in html_files) {
  x <- readLines(html_file, warn = FALSE, encoding = "UTF-8")
  
  metadata_lines <-
    grepl('rel="canonical"', x, fixed = TRUE) |
    grepl('rel="alternate"', x, fixed = TRUE)
  
  if (any(metadata_lines)) {
    x[metadata_lines] <- gsub(
      'href="/',
      paste0('href="', base_url, "/"),
      x[metadata_lines],
      fixed = TRUE
    )
    
    writeLines(x, html_file, useBytes = TRUE)
  }
}

# Normalize root-relative URLs in sitemap.xml.
sitemap_file <- file.path(site_output, "sitemap.xml")

if (file.exists(sitemap_file)) {
  x <- readLines(sitemap_file, warn = FALSE, encoding = "UTF-8")
  
  x <- gsub(
    "<loc>/",
    paste0("<loc>", base_url, "/"),
    x,
    fixed = TRUE
  )
  
  writeLines(x, sitemap_file, useBytes = TRUE)
}
# The root sitemap contains both languages. Point the English robots file
# to that real sitemap instead of a non-existent /en/sitemap.xml.
en_robots <- file.path(site_output, "en", "robots.txt")
if (file.exists(en_robots)) {
  writeLines(
    "Sitemap: https://hasansarici.com/sitemap.xml",
    en_robots,
    useBytes = TRUE
  )
}

message("PDF CVler ve web sitesi başarıyla güncellendi.")
