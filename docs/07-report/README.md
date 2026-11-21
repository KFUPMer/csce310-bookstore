# The course report and the submission

The course asks for three things, uploaded as one file:

| Asked for | Here |
|---|---|
| 1. Source code | This repository, as a zip made from git (below) |
| 2. Links to YouTube recordings of user acceptance testing of all functional requirements | Four videos, recorded with [uat-video-script.md](uat-video-script.md); their links go in [video-links.json](video-links.json) and into section 5 of the report |
| 3. A report on the database design and the application design and implementation | `report.pdf`, built from the files in this folder |

## The report

Four sections, as the course lists them, plus the videos:

| Section | File | What it holds |
|---|---|---|
| 1. Database design | [sections/1-database.html](sections/1-database.html) | Entities, every attribute with its type and keys, relationships (also across MySQL and MongoDB), the ER diagram |
| 2. Backend design | [sections/2-backend.html](sections/2-backend.html) | All 20 REST endpoints: URL format, who may call it, request and response JSON, error statuses |
| 3. Frontend design | [sections/3-frontend.html](sections/3-frontend.html) | The wireframes, then a screenshot of every major screen of both apps, with the requirements each serves |
| 4. Architectural and class design | [sections/4-architecture.html](sections/4-architecture.html) | Components; client/server, three tiers, the four layers, Model-View-Controller; every class with its layer, MVC role and job |
| 5. User acceptance test videos | [report-shell.html](report-shell.html), [video-links.json](video-links.json) | The video links, and which video and step shows each FR |

Every fact was taken from the code and the schema as they are, and checked against them by a second reader.

Build it from the repository root (needs Python and Microsoft Edge):

```
python tools/report/build_report.py
```

It writes `report.html` and `report.pdf` here. Both are rebuilt, not stored in git: the PDF is about 16 MB because it holds the screenshots at full size. The cover has blank lines for the student's name and ID.

## Making the files to upload

1. Record the four videos with [uat-video-script.md](uat-video-script.md), upload them to YouTube as Unlisted, and put each link in [video-links.json](video-links.json).
2. Build the report: `python tools/report/build_report.py`.
3. From the repository root, make the source zip from git, so only committed files go in (no `services/.env`, no build output):

   ```
   git archive --format=zip --prefix=csce310-bookstore/ -o submission/csce310-bookstore-source.zip HEAD
   ```

4. Put `report.pdf` next to it in `submission/`, and zip the folder if the course takes one file.
