# Dr. Hasan Sarıcı — Academic Website

Source repository for the bilingual academic website at **https://hasansarici.com**.

The site is built with Quarto, R, babelquarto and Typst, then validated and deployed to GitHub Pages with GitHub Actions.

## Source of truth

Academic information is maintained primarily in structured CSV files under `data/`. Website pages and both downloadable CV PDFs are generated from these shared data sources.

```text
data/                  structured academic data
R/                     rendering helper functions
_pdf/                  PDF CV source documents
scripts/               deployment validation tools
assets/                 static assets and generated downloadable PDFs
.github/workflows/      deployment and live-site health checks
build_site.R            single build entry point
MAINTENANCE.md          long-term maintenance and recovery runbook
```

Do **not** manually edit `_site/` or the generated PDFs under `assets/documents/`. Change the source data/code and rebuild instead.

## Local build

From RStudio:

```r
site_dir <- path.expand("~/Documents/hasan-sarici-website")
source(file.path(site_dir, "build_site.R"), chdir = TRUE)
```

## Validate before publishing

```r
system2(
  "python3",
  c(
    shQuote(file.path(site_dir, "scripts", "validate_site.py")),
    shQuote(file.path(site_dir, "_site"))
  )
)
```

A valid build prints `SITE VALIDATION PASSED`. The same validator runs in CI and blocks deployment if required pages/PDFs are missing, local links are broken, or canonical/hreflang/sitemap/robots metadata are inconsistent.

## Deployment

A push to `main` triggers `.github/workflows/deploy.yml`. The production workflow uses pinned toolchain/action versions, builds both PDF CVs and the multilingual website, validates the rendered artifact, and only then deploys to GitHub Pages.

A separate weekly workflow checks the live Turkish/English home pages, sitemap, both CV PDFs and the `www` redirect.

## Maintenance

Before changing the site, read **[MAINTENANCE.md](MAINTENANCE.md)**. It contains the standard update sequence, publication-status rules, dependency policy, backup procedure, annual domain/account checks and recovery steps.
