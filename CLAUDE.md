# CRM Mobile App — Project Instructions

## Goal
Build a premium, futuristic CRM experience for iOS and Android with a polished interface, fast interactions, reliable data handling, and maintainable code. Prefer clear, production-ready solutions over demos or unnecessary abstraction.

## Before changing code
- Inspect the existing project structure, package scripts, framework, design system, and current conventions before proposing changes.
- Reuse existing components, dependencies, and patterns when reasonable. Do not replace architecture or install packages without a concrete reason.
- For non-trivial work, state a short plan, then implement in small, verifiable steps.
- Ask before destructive changes, broad rewrites, schema migrations, or changes that affect external services.

## Product and UX
- Prioritize the primary CRM workflows: contacts, companies, leads, deals/pipeline, tasks, activities, search, notifications, and account/settings—only implement modules relevant to the current request.
- Design mobile-first. Respect safe areas, keyboard behavior, touch target sizes, loading/empty/error/success states, and navigation conventions for each platform.
- Aim for a distinctive premium visual system: strong hierarchy, restrained gradients/glows, intentional depth, crisp typography, consistent spacing, and purposeful motion. Avoid visual noise, excessive glass effects, and decoration that harms readability.
- Keep interactions responsive. Animations should be subtle, interruptible, and disabled or reduced when appropriate.
- Accessibility is a requirement: semantic labels, adequate contrast, scalable text, screen-reader support, and reduced-motion alternatives.

## Engineering
- Follow the repository's established language, framework, architecture, naming, formatting, and state-management patterns.
- Keep components focused and reusable where reuse is real; avoid premature abstractions and giant components.
- Type data at system boundaries and validate untrusted input. Handle failures explicitly; never silently swallow errors.
- Never hardcode secrets, tokens, credentials, or private user data. Use the project's approved configuration and secure storage.
- For network/data work, consider timeouts, retries where safe, pagination, cancellation, offline/poor-network behavior, and clear user feedback.
- Protect CRM data with least privilege, authorization checks, safe logging, and appropriate handling of personal information.

## Performance
- Measure or identify the likely bottleneck before adding complexity.
- Avoid unnecessary re-renders, repeated requests, large synchronous work on the UI thread, and unbounded lists.
- Use pagination/virtualization for large datasets, cache only with a clear invalidation strategy, and optimize images/assets appropriately.
- Keep startup and navigation paths lean. Do not add dependencies for trivial functionality.

## Verification
- Inspect available scripts before choosing commands. Run the most relevant lint, type-check, test, and build commands that are practical.
- Add or update tests for behavior changes and bug fixes. Test loading, empty, error, and success states for important flows.
- Report what changed, what was verified, and any checks that could not be run. Never claim a test passed unless it actually ran and passed.

## Working efficiently
- Keep changes scoped to the user's request; avoid unrelated cleanup.
- Prefer concise answers and small diffs. Do not dump huge logs or entire files unless needed.
- For large tasks, break work into milestones and summarize current state before continuing.
- Use a relevant skill in `.claude/skills/` when the task matches it. Read the skill's `SKILL.md` before applying its workflow.

## Flutter hot reload (regla oficial de flutter/agent-plugins)
- Tras editar archivos `.dart` bajo `lib/`, conéctate a la app en ejecución con la herramienta `dtd` del servidor MCP de Dart y ejecuta `hot_reload` (cambios de UI o métodos simples) o `hot_restart` (lógica base, `initState`, estado global/estático o `main()`).
- No lo hagas para cambios fuera de `lib/` (`test/`, `integration_test/`, etc.) ni cuando solo cambian comentarios, documentación o espacios en blanco.
- Si no hay una app en ejecución, indícalo en el reporte en lugar de omitirlo en silencio.
