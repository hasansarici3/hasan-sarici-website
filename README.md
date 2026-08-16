# Dr. Hasan Sarıcı — Academic Website

Source repository for the bilingual academic website of Dr. Hasan Sarıcı.

The website is built with:

- Quarto
- R
- babelquarto
- Typst
- GitHub Pages

Academic data are maintained in structured CSV files under `data/`.
The website and downloadable CV files are generated from these shared data sources.

## Local build

```r
source("build_site.R")
```

## Structure

```text
data/        structured academic data
R/           rendering helper functions
_pdf/        PDF CV source documents
assets/      static website assets
```
