---
name: architecture-review
description: Review or plan CRM app architecture, data flow, API integration, state management, security boundaries, maintainability, or a risky cross-cutting change. Use before major refactors or when architecture decisions matter.
---

# CRM Architecture Review

## Workflow
1. Inspect the repository structure, entry points, dependencies, scripts, and current patterns.
2. Trace the relevant user flow end to end: UI → state/domain logic → API/storage → response/error handling.
3. Separate observed facts from assumptions. Do not invent files, APIs, endpoints, or backend capabilities.
4. Identify the smallest change that fits the existing architecture. Compare alternatives only when the trade-off matters.
5. For risky or cross-cutting changes, propose a concise plan and wait for approval before destructive work.
6. Implement in small steps and verify the changed flow.

## Review dimensions
- **Boundaries:** Are UI, domain logic, data access, and platform-specific concerns separated appropriately?
- **Data model:** Are entities, IDs, nullability, relationships, and status transitions explicit?
- **State:** Is state ownership clear? Can stale data, race conditions, duplicate submissions, or invalid transitions occur?
- **API and persistence:** Are loading/error states, timeouts, pagination, cancellation, retries, caching, and offline behavior handled appropriately?
- **Security:** Are authorization checks enforced server-side where required? Are secrets excluded from source control and logs? Is sensitive CRM data minimized?
- **Reliability:** Are errors observable and actionable? Are writes idempotent where necessary? Are partial failures handled?
- **Performance:** Are large lists paginated, expensive work kept off the UI thread, and requests/re-renders controlled?
- **Testing:** Are business rules and failure paths testable without brittle UI-only tests?
- **Maintainability:** Does the proposal follow established conventions and avoid unnecessary dependencies or abstraction?

## Output format
Keep the review concise and actionable:
1. **Findings** ordered by severity (critical/high/medium/low), each tied to specific files or evidence.
2. **Recommended approach** with rationale and alternatives only where useful.
3. **Implementation plan** in small steps.
4. **Risks and assumptions** that need confirmation.
5. **Verification**: commands/tests to run and results actually observed.

Do not claim a vulnerability or defect without evidence. Distinguish confirmed issues from potential risks. Avoid broad rewrites unless the evidence justifies them.
