# Dr. Hasan Sarıcı — Academic Website

Source repository for the bilingual academic website at **https://hasansarici.com**.

The site is built with Quarto, R, babelquarto and Typst, then validated and deployed to GitHub Pages with GitHub Actions.

## Normal content management

For routine academic updates, the human-facing source is the Dropbox workbook:

```text
Dropbox/Hasan_Sarici_Website/website_content.xlsx
```

The workbook contains separate sheets for profile, research interests, education, experience, teaching, publications, projects, research networks, professional information and conferences.

After editing and saving the workbook, open this repository in RStudio and **Source `UPDATE_WEBSITE.R`**. The script:

1. refuses to overwrite uncommitted local work;
2. synchronizes `main` with `git pull --ff-only`;
3. locates the Dropbox workbook automatically;
4. validates required sheets, columns, IDs, controlled statuses and destructive deletions;
5. creates a timestamped workbook backup in Dropbox;
6. converts workbook sheets into the existing `data/*.csv` files;
7. rebuilds both PDF CVs and the bilingual website;
8. runs `scripts/validate_site.py`;
9. shows the Git changes and asks for explicit `EVET` confirmation;
10. commits and pushes the managed files;
11. copies the latest PDF CVs to Dropbox and creates a verified Git bundle backup.

This keeps editing simple without putting the active Git repository inside Dropbox.

## Technical source of truth

The deployable, version-controlled academic data remains under `data/`. Those CSV files are what the site and CV renderers read, and every published change is preserved in Git history. Under normal operation they are generated from `website_content.xlsx` rather than edited manually.

```text
UPDATE_WEBSITE.R        one-click Dropbox -> validate -> build -> GitHub workflow
data/                   version-controlled academic build data
R/                      rendering helper functions
_pdf/                   PDF CV source documents
scripts/                deployment validation tools
assets/                 static assets and generated downloadable PDFs
.github/workflows/      deployment and live-site health checks
build_site.R            single build entry point
MAINTENANCE.md          long-term maintenance and recovery runbook
```

Do **not** manually edit `_site/` or the generated PDFs under `assets/documents/`. Change the workbook/source data/code and rebuild instead.

## Preferred routine update

From RStudio, open `UPDATE_WEBSITE.R` and click **Source**.

The script will stop before publishing and show the files that changed. Only after you type `EVET` will it commit and push the update.

## Manual local build

For infrastructure/development work that is not a normal workbook update:

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

Before infrastructure changes, read **[MAINTENANCE.md](MAINTENANCE.md)**. It contains the routine Dropbox update sequence, publication-status rules, dependency policy, backup procedure, annual domain/account checks and recovery steps.
