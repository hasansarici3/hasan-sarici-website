#!/usr/bin/env python3
"""Validate the rendered academic website before deployment.

Uses only the Python standard library so GitHub Actions needs no extra packages.
"""
from __future__ import annotations

import sys
from html.parser import HTMLParser
from pathlib import Path, PurePosixPath
from urllib.parse import unquote, urlparse
from xml.etree import ElementTree as ET

BASE_URL = "https://hasansarici.com/"
OLD_SITE = "hasansarici3.github.io/hasan-sarici-website"

ROOT_PAGES = [
    "index.html",
    "about.html",
    "research.html",
    "publications.html",
    "projects.html",
    "seminars.html",
    "cv.html",
    "contact.html",
]
EN_PAGES = [f"en/{name}" for name in ROOT_PAGES]
EXPECTED_PAGES = ROOT_PAGES + EN_PAGES
EXPECTED_PDFS = [
    "assets/documents/Hasan_Sarici_Akademik_CV_TR.pdf",
    "assets/documents/Hasan_Sarici_Academic_CV_EN.pdf",
]
SKIP_SCHEMES = {"mailto", "tel", "javascript", "data"}


class SiteHTMLParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.references: list[tuple[str, str]] = []
        self.canonical: list[str] = []
        self.alternates: dict[str, list[str]] = {}

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        d = {k.lower(): v for k, v in attrs if v is not None}
        tag = tag.lower()

        if tag == "a" and d.get("href"):
            self.references.append(("href", d["href"]))
        if tag in {"img", "script", "iframe", "source", "video", "audio"} and d.get("src"):
            self.references.append(("src", d["src"]))
        if tag == "link" and d.get("href"):
            rel_tokens = {x.lower() for x in d.get("rel", "").split()}
            href = d["href"]
            self.references.append(("href", href))
            if "canonical" in rel_tokens:
                self.canonical.append(href)
            if "alternate" in rel_tokens and d.get("hreflang"):
                lang = d["hreflang"].lower()
                self.alternates.setdefault(lang, []).append(href)


def expected_canonical(rel: str) -> str:
    if rel == "index.html":
        return BASE_URL
    if rel == "en/index.html":
        return BASE_URL + "en/"
    return BASE_URL + rel


def expected_alternates(rel: str) -> dict[str, str]:
    name = PurePosixPath(rel).name
    # babelquarto emits language alternates using rendered HTML filenames,
    # including /index.html for both language home pages.
    return {
        "tr": BASE_URL + name,
        "en": BASE_URL + "en/" + name,
    }


def candidate_local_path(root: Path, source_rel: str, raw_url: str) -> Path | None:
    raw_url = raw_url.strip()
    if not raw_url or raw_url.startswith("#"):
        return None

    parsed = urlparse(raw_url)
    if parsed.scheme.lower() in SKIP_SCHEMES:
        return None

    if parsed.scheme in {"http", "https"}:
        if parsed.netloc.lower() not in {"hasansarici.com", "www.hasansarici.com"}:
            return None
        path = unquote(parsed.path)
        if not path or path == "/":
            path = "/index.html"
        elif path.endswith("/"):
            path += "index.html"
        return root / path.lstrip("/")

    if parsed.netloc:
        return None

    path = unquote(parsed.path)
    if not path:
        return None

    source_dir = PurePosixPath(source_rel).parent
    if path.startswith("/"):
        logical = PurePosixPath(path.lstrip("/"))
    else:
        logical = source_dir / PurePosixPath(path)

    parts: list[str] = []
    for part in logical.parts:
        if part in {"", "."}:
            continue
        if part == "..":
            if not parts:
                return root / "__ESCAPES_SITE_ROOT__"
            parts.pop()
        else:
            parts.append(part)

    if not parts:
        parts = ["index.html"]
    local = root.joinpath(*parts)
    if path.endswith("/"):
        local = local / "index.html"
    return local


def validate(root: Path) -> list[str]:
    errors: list[str] = []

    if not root.is_dir():
        return [f"Rendered site directory not found: {root}"]

    for rel in EXPECTED_PAGES:
        path = root / rel
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"Missing expected HTML page: {rel}")

    for rel in EXPECTED_PDFS:
        path = root / rel
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"Missing or empty PDF: {rel}")

    for rel in EXPECTED_PAGES:
        path = root / rel
        if not path.is_file():
            continue

        text = path.read_text(encoding="utf-8")
        if OLD_SITE in text:
            errors.append(f"Old GitHub Pages URL remains in {rel}")

        parser = SiteHTMLParser()
        try:
            parser.feed(text)
        except Exception as exc:
            errors.append(f"Could not parse {rel}: {exc}")
            continue

        expected_can = expected_canonical(rel)
        if parser.canonical != [expected_can]:
            errors.append(
                f"Canonical mismatch in {rel}: expected {expected_can!r}, got {parser.canonical!r}"
            )

        expected_alt = expected_alternates(rel)
        for lang, expected_url in expected_alt.items():
            urls = parser.alternates.get(lang, [])
            if expected_url not in urls:
                errors.append(
                    f"Missing/incorrect hreflang {lang!r} in {rel}: expected {expected_url!r}, got {urls!r}"
                )
            for url in urls:
                if not url.startswith(BASE_URL):
                    errors.append(f"Non-canonical hreflang URL in {rel}: {url}")
                if OLD_SITE in url:
                    errors.append(f"Old domain in hreflang URL in {rel}: {url}")

        for attr, raw_url in parser.references:
            if ".qmd" in urlparse(raw_url).path.lower():
                errors.append(f"Unrendered .qmd {attr} in {rel}: {raw_url}")

            if OLD_SITE in raw_url:
                errors.append(f"Old GitHub Pages URL in {rel}: {raw_url}")

            target = candidate_local_path(root, rel, raw_url)
            if target is None:
                continue
            if target.name == "__ESCAPES_SITE_ROOT__":
                errors.append(f"Reference escapes site root in {rel}: {raw_url}")
                continue
            if not target.exists():
                try:
                    shown = target.relative_to(root).as_posix()
                except ValueError:
                    shown = str(target)
                errors.append(f"Broken local {attr} in {rel}: {raw_url} -> {shown}")

    sitemap = root / "sitemap.xml"
    if not sitemap.is_file():
        errors.append("Missing sitemap.xml")
    else:
        raw = sitemap.read_text(encoding="utf-8")
        if OLD_SITE in raw:
            errors.append("Old GitHub Pages URL remains in sitemap.xml")
        try:
            tree = ET.fromstring(raw)
            locs = {
                (node.text or "").strip()
                for node in tree.iter()
                if node.tag.endswith("loc") and (node.text or "").strip()
            }
            expected_locs = {BASE_URL + rel for rel in EXPECTED_PAGES}
            missing = sorted(expected_locs - locs)
            unexpected = sorted(locs - expected_locs)
            if missing:
                errors.append("sitemap.xml missing: " + ", ".join(missing))
            if unexpected:
                errors.append("sitemap.xml has unexpected URLs: " + ", ".join(unexpected))
        except ET.ParseError as exc:
            errors.append(f"Invalid sitemap.xml: {exc}")

    robots_expected = "Sitemap: https://hasansarici.com/sitemap.xml"
    for rel in ["robots.txt", "en/robots.txt"]:
        path = root / rel
        if not path.is_file():
            errors.append(f"Missing {rel}")
            continue
        text = path.read_text(encoding="utf-8").strip()
        if robots_expected not in text:
            errors.append(f"Incorrect sitemap directive in {rel}: {text!r}")
        if OLD_SITE in text:
            errors.append(f"Old GitHub Pages URL remains in {rel}")

    return errors


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("_site")
    root = root.resolve()
    errors = validate(root)

    if errors:
        print(f"SITE VALIDATION FAILED ({len(errors)} issue(s))")
        for error in errors:
            print(f" - {error}")
        return 1

    print("SITE VALIDATION PASSED")
    print(f" - {len(EXPECTED_PAGES)} bilingual HTML pages present")
    print(f" - {len(EXPECTED_PDFS)} PDF CVs present and non-empty")
    print(" - internal links/assets, canonical URLs, hreflang, sitemap, and robots.txt valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
