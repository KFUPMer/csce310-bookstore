"""book-service: search books, and add and update them. Python Flask and MongoDB.

Layers, each of which only calls the one below it (docs/02-design/engineering-rules.md):

    routes.py      receives requests, checks who is asking, returns JSON
    services.py    the rules
    repository.py  reads and writes MongoDB
    models.py      plain data

Beside them: schemas.py (what a request must contain), auth.py (asks
user-service who a token belongs to), errors.py, config.py, and app.py, which
puts the parts together.
"""
