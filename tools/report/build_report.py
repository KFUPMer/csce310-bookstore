"""Build the course report: docs/07-report/report.html and report.pdf.

What it does:
  1. Reads the shell, docs/07-report/report-shell.html.
  2. Puts in the section fragments, docs/07-report/sections/1-*.html to 4-*.html, in order.
     Each is wrapped in <section id="..."> so the table of contents can link to it.
     A missing fragment is created first as a placeholder holding only its <h2>;
     an existing fragment is never overwritten.
  3. Fills {{DATE}} (today), {{VERSION}} (the latest git tag) and {{VIDEOS}}
     (rows made from docs/07-report/video-links.json; an empty url shows "link to be added").
  4. Writes docs/07-report/report.html.
  5. Prints it to docs/07-report/report.pdf with Microsoft Edge headless, and prints the PDF size.
  6. Checks itself: the PDF exists and is over 50 KB, and the HTML has all four section headings.

How to run it, from the repo root:
  python tools/report/build_report.py

Python standard library only. Needs Microsoft Edge in its usual place on Windows.
"""

import datetime
import html
import json
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
REPORT_DIR = ROOT / "docs" / "07-report"
SHELL = REPORT_DIR / "report-shell.html"
SECTIONS_DIR = REPORT_DIR / "sections"
VIDEOS_JSON = REPORT_DIR / "video-links.json"
OUT_HTML = REPORT_DIR / "report.html"
OUT_PDF = REPORT_DIR / "report.pdf"
EDGE = pathlib.Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe")

# File name, anchor id (used by the table of contents), and the heading a placeholder gets.
SECTIONS = [
    ("1-database.html", "database", "1. Database design"),
    ("2-backend.html", "backend", "2. Backend design"),
    ("3-frontend.html", "frontend", "3. Frontend design"),
    ("4-architecture.html", "architecture", "4. Architectural and class design"),
]


def make_missing_sections():
    """Create a placeholder for each section file that does not exist yet. Never overwrites."""
    SECTIONS_DIR.mkdir(parents=True, exist_ok=True)
    for name, _, heading in SECTIONS:
        path = SECTIONS_DIR / name
        if not path.exists():
            path.write_text(f"<h2>{heading}</h2>\n<p>To be written.</p>\n", encoding="utf-8")
            print(f"Created placeholder {path.relative_to(ROOT)}")


def sections_html():
    parts = []
    for name, anchor, _ in SECTIONS:
        body = (SECTIONS_DIR / name).read_text(encoding="utf-8")
        parts.append(f'<section id="{anchor}">\n{body.strip()}\n</section>')
    return "\n\n".join(parts)


def latest_tag():
    result = subprocess.run(
        ["git", "describe", "--tags", "--abbrev=0"], cwd=ROOT, capture_output=True, text=True, check=False
    )
    tag = result.stdout.strip()
    return tag if result.returncode == 0 and tag else "unreleased"


def video_rows():
    videos = json.loads(VIDEOS_JSON.read_text(encoding="utf-8"))
    rows = []
    for number, video in enumerate(videos, start=1):
        url = video.get("url", "").strip()
        if url.startswith("https://"):
            safe = html.escape(url, quote=True)
            link = f'<a href="{safe}">{safe}</a>'
        else:
            link = "<em>link to be added</em>"
        rows.append(
            f"      <tr><td>{number}</td><td>{html.escape(video['title'])}</td>"
            f"<td>{html.escape(video['covers'])}</td><td>{link}</td></tr>"
        )
    return "\n".join(rows)


def build_html():
    page = SHELL.read_text(encoding="utf-8")
    for placeholder in ("{{DATE}}", "{{VERSION}}", "{{SECTIONS}}", "{{VIDEOS}}"):
        assert placeholder in page, f"The shell has no {placeholder}"
    page = page.replace("{{SECTIONS}}", sections_html())
    page = page.replace("{{VIDEOS}}", video_rows())
    page = page.replace("{{DATE}}", datetime.date.today().strftime("%d %B %Y").lstrip("0"))
    page = page.replace("{{VERSION}}", latest_tag())
    OUT_HTML.write_text(page, encoding="utf-8")
    print(f"Wrote {OUT_HTML.relative_to(ROOT)}")
    return page


def print_pdf():
    if not EDGE.exists():
        sys.exit(f"Microsoft Edge not found at {EDGE}")
    if OUT_PDF.exists():
        OUT_PDF.unlink()
    # A separate, temporary profile, so an Edge window the user has open does not interfere.
    with tempfile.TemporaryDirectory() as profile:
        command = [
            str(EDGE),
            "--headless",
            "--disable-gpu",
            "--no-first-run",
            f"--user-data-dir={profile}",
            "--no-pdf-header-footer",
            "--virtual-time-budget=15000",  # time for fonts and images to load before printing
            f"--print-to-pdf={OUT_PDF}",
            OUT_HTML.as_uri(),
        ]
        subprocess.run(command, capture_output=True, text=True, timeout=180, check=False)
    print(f"Wrote {OUT_PDF.relative_to(ROOT)}: {OUT_PDF.stat().st_size / 1024:.0f} KB" if OUT_PDF.exists() else "No PDF was written")


def main():
    make_missing_sections()
    page = build_html()
    print_pdf()

    # Self-check.
    assert OUT_PDF.exists(), "report.pdf was not written"
    assert OUT_PDF.stat().st_size > 50 * 1024, f"report.pdf is only {OUT_PDF.stat().st_size} bytes"
    for name, anchor, _ in SECTIONS:
        start = page.index(f'<section id="{anchor}">')
        end = page.index("</section>", start)
        assert "<h2" in page[start:end], f"Section {anchor} ({name}) has no <h2> heading"
    for placeholder in ("{{DATE}}", "{{VERSION}}", "{{SECTIONS}}", "{{VIDEOS}}"):
        assert placeholder not in page, f"{placeholder} was left in report.html"
    print("Self-check passed")


if __name__ == "__main__":
    main()
