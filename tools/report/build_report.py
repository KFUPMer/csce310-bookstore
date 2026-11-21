"""Build the course report: docs/07-report/report.html and report.pdf.

What it does:
  1. Reads the shell, docs/07-report/report-shell.html.
  2. Puts in the section fragments, docs/07-report/sections/1-*.html to 4-*.html, in order.
     Each is wrapped in <section id="..."> so the table of contents can link to it.
     A missing fragment stops the build: the report must never go out with a section left out.
  3. Fills {{DATE}} (today), {{VERSION}} (the latest git tag) and {{VIDEOS}}
     (rows made from docs/07-report/video-links.json; an empty url shows "link to be added",
     and a url that does not start with https:// stops the build).
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
STUDENT_JSON = REPORT_DIR / "student.json"  # {"name": ..., "id": ...}; not in git
OUT_HTML = REPORT_DIR / "report.html"
OUT_PDF = REPORT_DIR / "report.pdf"
EDGE = pathlib.Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe")

# File name, and anchor id (used by the table of contents).
SECTIONS = [
    ("1-database.html", "database"),
    ("2-backend.html", "backend"),
    ("3-frontend.html", "frontend"),
    ("4-architecture.html", "architecture"),
]


def sections_html():
    parts = []
    for name, anchor in SECTIONS:
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
        elif url:
            # Not silently shown as "link to be added": the uploaded report would look untested (P-023).
            sys.exit(f"Video {number}: the link must start with https:// (it is {url!r}). Copy it from YouTube's Share button.")
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
    # The student's name and ID: from student.json, which git ignores (the repository is public).
    student = json.loads(STUDENT_JSON.read_text(encoding="utf-8")) if STUDENT_JSON.exists() else {}
    blank = "_" * 32
    page = page.replace("{{STUDENT_NAME}}", html.escape(student.get("name") or blank))
    page = page.replace("{{STUDENT_ID}}", html.escape(student.get("id") or blank))
    page = page.replace("{{COURSE}}", html.escape(student.get("course") or "CSCE 310"))
    page = page.replace("{{INSTRUCTOR}}", html.escape(student.get("instructor") or blank))
    # The footer of every page after the cover; it sits inside a CSS string, so quotes and backslashes are escaped.
    footer = " · ".join(x for x in (student.get("course") or "CSCE 310", f"Instructor: {student['instructor']}" if student.get("instructor") else "") if x)
    page = page.replace("{{FOOTER}}", footer.replace("\\", "\\\\").replace('"', '\\"'))
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
    page = build_html()
    print_pdf()

    # Self-check.
    assert OUT_PDF.exists(), "report.pdf was not written"
    assert OUT_PDF.stat().st_size > 50 * 1024, f"report.pdf is only {OUT_PDF.stat().st_size} bytes"
    for name, anchor in SECTIONS:
        start = page.index(f'<section id="{anchor}">')
        end = page.index("</section>", start)
        assert "<h2" in page[start:end], f"Section {anchor} ({name}) has no <h2> heading"
    for placeholder in ("{{DATE}}", "{{VERSION}}", "{{SECTIONS}}", "{{VIDEOS}}"):
        assert placeholder not in page, f"{placeholder} was left in report.html"
    print("Self-check passed")


if __name__ == "__main__":
    main()
