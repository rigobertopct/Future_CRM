# Performance rules

- Prefer measured evidence or a clearly explained likely bottleneck over speculative optimization.
- Avoid unnecessary re-renders, duplicate network calls, unbounded lists, large synchronous UI-thread work, and oversized assets.
- Paginate or virtualize large CRM lists when supported by the framework.
- Cache only with an explicit freshness/invalidation strategy.
- Cancel obsolete requests when possible; prevent stale responses from overwriting newer state.
- Keep startup paths and navigation-critical code lean.
- Do not add dependencies or complex abstractions for marginal gains.
- Verify improvements with available profiling, tests, or reproducible observations; state when performance has not been measured.
