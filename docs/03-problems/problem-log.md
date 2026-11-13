# Problem log

Every problem that cost real time or changed a decision gets an entry here. The goal is to show how the project actually went, not only the result.

## How to add an entry

Copy the template, give it the next number, and link the GitHub issue and the commit or patch version that fixed it.

```markdown
## P-000 — Short title

- **Date found:** YYYY-MM-DD
- **Phase / milestone:** e.g. M3 Backend
- **Issue:** #number
- **Status:** Open | Solved | Worked around

**What happened**
What we saw, and what we expected instead.

**Cause**
What was actually wrong (once known).

**What we tried**
1. First attempt — result
2. Second attempt — result

**Solution**
What fixed it. Fixed in version vX.Y.Z (commit abc1234).

**Lesson**
What we do differently from now on.
```

---

## Entries

## P-001 — Backend designed on the wrong technology

- **Date found:** 2026-11-13
- **Phase / milestone:** M1 Idea & Requirements
- **Issue:** —
- **Status:** Solved

**What happened**
The first design used Spring Boot (Java) for all three backend services. It was written from the PRD's introduction, which says the services are "built with Java or Python Flask", before section 4 (non-functional requirements) had been read.

**Cause**
Section 4.1 fixes the technology of each service: user services in Java HttpServer, book services in Python Flask, order and billing services in Python Flask. Spring Boot is not one of the options, and two of the three services cannot be Java at all.

**What we tried**
1. Checked whether "Java everywhere" could still satisfy the PRD — it cannot; 4.1 is explicit per service.

**Solution**
Changed the stack in every document and in the architecture diagram: user-service → Java HttpServer, book-service and order-service → Python Flask, clients stay JavaFX (which also earns +2%). `catalog-service` was renamed `book-service` to match the PRD's wording. No code existed yet, so nothing had to be rewritten.

**Lesson**
Read the whole requirements document, including the non-functional part, before choosing technology. Caught in M1, this cost one documentation update; caught in M3 it would have cost a rewrite of the backend.
