---
name: seo-audit
description: Audit or improve public-facing web pages for technical SEO, metadata, crawlability, performance, structured data, and accessible content. Use only when the CRM includes a public website, marketing site, or indexable web app; do not apply SEO assumptions to private authenticated CRM screens.
---

# SEO Audit

## Scope gate
First determine whether the target is public and intended to be indexed. Authenticated CRM pages, private records, customer data, and internal app screens should not be indexed; prioritize privacy and correct access controls instead.

## Workflow
1. Inspect the framework, routes, rendering strategy, metadata implementation, sitemap/robots files, and existing analytics/search tooling.
2. Identify the actual page types and their intended search intent. Do not invent keywords, traffic, rankings, or business goals.
3. Audit the relevant checks below and distinguish confirmed defects from recommendations.
4. Make targeted changes consistent with the framework. Avoid adding an SEO dependency unless needed.
5. Run relevant tests/build checks and summarize findings and verification.

## Technical checks
- Unique, accurate page titles and meta descriptions for indexable pages.
- Correct canonical URLs where duplicate URL variants exist.
- Appropriate robots directives and `robots.txt`; never expose private routes or data.
- Valid sitemap containing only canonical, indexable URLs that should be public.
- Correct HTTP status codes, redirects, and not-found handling.
- Server rendering or pre-rendering where required by the app and framework.
- Structured data only when it truthfully describes visible page content and follows the relevant schema.
- Open Graph/social metadata where useful.
- Internal links, descriptive headings, image alternatives, and meaningful link text.
- Mobile usability, performance, and Core Web Vitals where measurement is available.
- Avoid duplicate, thin, misleading, or automatically generated pages with little value.

## Privacy and security
- Never recommend indexing authenticated CRM routes, contact records, deals, reports, or private customer data.
- Do not place personal or confidential information in metadata, URLs, logs, or structured data.
- Treat robots directives as crawl guidance, not an access-control mechanism. Access control must be enforced separately.

## Reporting
Return:
1. Priority-ranked findings with evidence and affected routes/files.
2. Recommended fixes, separating required fixes from optional improvements.
3. Changes made, if implementation was requested.
4. Verification performed and any limitations.
