# Benzene

Benzene is a lightweight, read-only service and client for serving national-scale UK fuel station (forecourt) data, focused on fast “nearby” queries and simple station lookups. The backend materializes a CSV data source into Postgres/PostGIS on a scheduled refresh, exposing a small HTTP API, while the frontend is a web app that can also be packaged as an Android app via Capacitor. The project is intentionally simple, cheap to run, and designed to scale by caching and bounded queries rather than complex infrastructure.
