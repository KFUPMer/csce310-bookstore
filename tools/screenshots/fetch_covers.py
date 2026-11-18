"""Download every cover photo in database/mongodb/books.json, for the apps' screenshot tests.

Tests have no internet, so the screenshot tests read the photos from this cache instead.
The cache is in clients/build-cover-cache, which git ignores: the photos are the
publishers' artwork and are not stored in the repository.

Run from the repository root:  python tools/screenshots/fetch_covers.py
Expected: one line per book, "cached" or "already there"; any failure is printed and skipped.
"""
import json
import re
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parents[2]
CACHE = ROOT / "clients" / "build-cover-cache"
HEADERS = {"User-Agent": "csce310-course-project/1.0 (screenshot covers)"}


def cache_name(url: str) -> str:
    """The same name the screenshot tests look for (coverCacheName in their Dart code)."""
    return re.sub(r"[^A-Za-z0-9]", "_", url) + ".jpg"


def main():
    CACHE.mkdir(exist_ok=True)
    books = json.loads((ROOT / "database" / "mongodb" / "books.json").read_text(encoding="utf-8"))
    for book in books:
        url = book.get("coverUrl")
        if not url:
            continue
        target = CACHE / cache_name(url)
        if target.exists():
            print(f"already there  {book['title']}")
            continue
        try:
            answer = requests.get(url, headers=HEADERS, timeout=30)
            answer.raise_for_status()
            target.write_bytes(answer.content)
            print(f"cached         {book['title']} ({len(answer.content) // 1024} KB)")
        except requests.RequestException as error:
            print(f"FAILED         {book['title']}: {error}")


if __name__ == "__main__":
    main()
