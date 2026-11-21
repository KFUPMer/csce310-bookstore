# The course report and the submission

The course asks for three things, uploaded as one file:

| Asked for | Here |
|---|---|
| 1. Source code | This repository, as a zip made from git (below) |
| 2. Links to YouTube recordings of user acceptance testing of all functional requirements | One video, recorded with [uat-video-script.md](uat-video-script.md); its link goes in [video-links.json](video-links.json) and into section 5 of the report |
| 3. A report on the database design and the application design and implementation | `report.pdf`, built from the files in this folder |

## The report

Four sections, as the course lists them, plus the video. About 25 pages: short on purpose, so it proves the design without making the reader dig. The full detail stays in `docs/02-design`.

| Section | File | What it holds |
|---|---|---|
| 1. Database design | [sections/1-database.html](sections/1-database.html) | The entities with their attributes and keys, the relationships (also across MySQL and MongoDB), the ER diagram |
| 2. Backend design | [sections/2-backend.html](sections/2-backend.html) | The rules, all 20 endpoints with their input and output, and real JSON for the main flows (log in, search, order, payment, report) |
| 3. Frontend design | [sections/3-frontend.html](sections/3-frontend.html) | A screenshot of every major screen of both apps, two to a page, with the requirements each serves |
| 4. Architectural and class design | [sections/4-architecture.html](sections/4-architecture.html) | Components; client/server, three tiers, the four layers, Model-View-Controller; the main classes and their roles; the class diagrams |
| 5. User acceptance test videos | [report-shell.html](report-shell.html), [video-links.json](video-links.json) | The video link, and where in it each FR is shown |

Every fact was taken from the code and the schema as they are.

Build it from the repository root (needs Python and Microsoft Edge):

```
python tools/report/build_report.py
```

It writes `report.html` and `report.pdf` here. Both are rebuilt, not stored in git: the PDF is about 13 MB because it holds the screenshots at full size. The student's name, ID, course, and instructor (on the cover and in each page's footer) come from `student.json` (`{"name": ..., "id": ..., "course": ..., "instructor": ...}`) in this folder, which git ignores so they stay out of the public repository; without it the cover has blank lines.

## Making the files to upload

1. Record the video with [uat-video-script.md](uat-video-script.md), upload it to YouTube as Unlisted, and put its link in [video-links.json](video-links.json).
2. Build the report: `python tools/report/build_report.py`.
3. From the repository root, make the source zip from git, so only committed files go in (no `services/.env`, no build output):

   ```
   git archive --format=zip --prefix=csce310-bookstore/ -o submission/csce310-bookstore-source.zip HEAD
   ```

4. Put `report.pdf` next to it in `submission/`, and zip the folder if the course takes one file.
