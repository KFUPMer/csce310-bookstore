# Versions and patches

Versions follow `vMAJOR.MINOR.PATCH`.

| Part | Changes when | Example |
|---|---|---|
| MINOR | A milestone is completed | M3 done → `v0.3.0` |
| PATCH | A bug is fixed in an already released version | fix in the backend release → `v0.3.1` |
| MAJOR | The final, submittable system is released | `v1.0.0` |

## Releasing a version

1. All issues in the milestone are closed.
2. `CHANGELOG.md` has a section for the version.
3. Tag `main` and push the tag, then publish a GitHub release from it.

```bash
git tag -a v0.3.0 -m "M3: backend services"
git push origin v0.3.0
gh release create v0.3.0 --title "v0.3.0 — Backend services" --notes-file release-notes.md
```

## Releasing a patch

1. Open a bug issue and, if it cost real time, a problem-log entry.
2. Fix it on a `fix/<issue>-<short-name>` branch and merge through a pull request.
3. Add the fix to `CHANGELOG.md` under a new patch version and tag it (e.g. `v0.3.1`).

## Branch names

| Type | Pattern | Example |
|---|---|---|
| New work | `feature/<issue>-<short-name>` | `feature/8-book-service` |
| Bug fix | `fix/<issue>-<short-name>` | `fix/21-order-total` |
| Documentation | `docs/<short-name>` | `docs/api-spec` |
