---
name: futuristic-ui
description: Design or improve premium futuristic mobile UI for a CRM, including visual hierarchy, interactions, motion, accessibility, and responsive states. Use when creating or refining screens, components, themes, or design systems.
---

# Futuristic CRM UI

## Objective
Create a premium, modern, futuristic interface that remains legible, accessible, and practical for daily CRM work. The result should feel intentional, not like a sci-fi dashboard overloaded with effects.

## Workflow
1. Inspect the existing screens, components, theme tokens, navigation, and framework. Identify existing conventions to preserve.
2. Clarify the screen's primary user goal and the most important action.
3. Define or reuse design tokens before adding one-off styles.
4. Implement the smallest cohesive change.
5. Check small and large phone layouts, keyboard/safe-area behavior, and relevant UI states.
6. Run available checks and summarize changed files and verification.

## Visual direction
- Use strong typography hierarchy, consistent spacing, aligned grids, and clear grouping.
- Use dark surfaces or light surfaces according to the existing product direction; do not impose a new theme without reason.
- Use gradients, accent colors, glow, blur, borders, and shadows sparingly and consistently.
- Prioritize content contrast and scanability over decorative effects.
- Use meaningful icons consistently; avoid mixing icon styles or using emoji as core UI icons.
- Keep primary actions visually distinct. Avoid competing accent colors and excessive pill-shaped containers.
- Prefer real product data patterns and realistic content over placeholder-heavy mockups.

## Motion and interaction
- Animate only when motion explains hierarchy, state change, navigation, or feedback.
- Keep durations short and easing consistent; avoid animations that block input.
- Respect reduced-motion settings where supported.
- Provide pressed, focused, disabled, loading, and error states where relevant.
- Prevent layout shifts and preserve state when navigating back.

## CRM-specific usability
- Make names, organizations, stages, owners, dates, and next actions easy to scan.
- For pipelines, make stage and status understandable without color alone.
- Search and filters should be discoverable and preserve useful selections.
- Forms should use appropriate keyboard types, validation, clear errors, and unsaved-change handling.
- Lists should handle loading, empty, failure, refresh, and large result sets.
- Keep destructive actions explicit and confirm when recovery is difficult.

## Accessibility and responsive checks
- Ensure contrast, scalable text, screen-reader labels, logical focus order, and usable touch targets.
- Check safe areas, notches, bottom navigation, landscape/tablet layouts if supported, and keyboard overlap.
- Do not rely on color, blur, animation, or hover alone to communicate information.

## Deliverable
After implementation, report:
- The key UI/UX changes.
- Any assumptions or design trade-offs.
- Checks run and anything still needing manual device testing.
