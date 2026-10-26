# Architecture rules

- Follow the existing repository architecture unless there is evidence it blocks the requested work.
- Keep UI, business logic, and data access separated to the degree appropriate for this project.
- Reuse established patterns and dependencies; avoid duplicate systems and premature abstraction.
- Validate untrusted data at system boundaries and represent errors explicitly.
- Never commit secrets or expose sensitive CRM data in logs, URLs, analytics, or client-side authorization assumptions.
- Make changes scoped and incremental; ask before broad refactors, destructive edits, or migrations.
