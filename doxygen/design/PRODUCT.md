<!-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-only -->

# Product: libmemalloc documentation

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Repository-inferred audience: library contributors and reviewers reading engineering standards,
governance and C API references. This inference comes from the published documents and API inputs;
it is not a claim of user research.

## Product Purpose

Make the project's authored documentation and documented C entities navigable in one generated site.
Success means readers can find a document or API entity, follow its references, read examples and
copy code while retaining the source document's meaning.

## Operating Context

This record describes the intended complete site. The standalone assets are available;
the generator integration and its full-site validation remain deferred with the build documentation.

Doxygen generates static HTML from C sources, the project README, selected Markdown pages and
Doxygen input. Readers use desktop and mobile browsers. The site supports direct file viewing;
network-dependent highlighting and diagrams require their supporting resources to be available.

The Lua filters live in `scripts/documentation/` relative to the repository root.
The planned driver entry point is `scripts/documentation/main.lua`.
Frontend assets live in `doxygen/web/styles/` and `doxygen/web/scripts/`. The pinned upstream theme
is integrated through the project stylesheets rather than edited directly.

## Capabilities and Constraints

- The project README is the home page. The Documentation tree follows the actual `docs/` hierarchy.
- `docs/**/README.md` indexes are excluded case-insensitively, including linked discovery;
  references to them point to their repository source.
- Project references are explicitly limited to GOVERNANCE, MAINTAINERS, REVIEWING, ROADMAP,
  SECURITY, SUPPORT, CHANGELOG, CODE_OF_CONDUCT, LICENSE and CONTRIBUTING. Other linked pages
  remain reachable through their links.
- Search, navigation and API references retain Doxygen's generated structure. The reading layer
  adds an expandable section index, theme choice, code copying, a skip link and table scrolling.
- Theme follows the system until the reader chooses light or dark; browser storage preserves an
  explicit choice when available. A failed clipboard operation selects code for manual copying.
- Authored text remains readable without JavaScript. Syntax highlighting and Mermaid rendering
  can require external resources; full-site validation remains part of the deferred integration.
- Documentation validation rejects warnings; it does not prove allocator correctness or usability.
- Independent navigation/outline controls let readers reclaim horizontal space. The browser
  title is `libmemalloc`; the document retains a descriptive heading.
- Native Doxygen graphs share Mermaid's SVG presentation and include textual relationships.
- Supported browsers expose read-only WebMCP tools for page content, headings and discovery.
  The interface does not depend on WebMCP availability or a remote agent service.

## Brand Commitments

Preserve the libmemalloc name, existing colored penguin illustrations and original logo assets.
Generate and retain a mascot-only header/favicon copy during publication, keeping the full original
on the home page. Use the subtitle “The Magic of Memory Transmutation”.
The user selected the Doxygen Awesome base with the libmemalloc visual identity.
Follow `assets/images/README.md`: Nunito Sans Bold for headings and branding, Regular for reading,
and the Endesga 32 blue and gray-blue accents in light mode. Dark mode uses neutral graphite
surfaces and soft blue links. Code alone uses JetBrains Mono, with the Nord syntax theme in both modes.
Keep the wide 1200px reading area, Mermaid SVG rendering and language-aware code highlighting.
Retain the upstream theme's navigation and component shapes, a right page index on wide screens,
content-width separators and the bottom-right GitHub repository corner. The generated attribution footer and
navigation synchronization control remain hidden. The visual rules are recorded in [DESIGN.md](DESIGN.md).

## Evidence on Hand

The actual content is in the repository README, `docs/`, the project reference pages and documented
`core/` entities. Full-site integration and verification commands remain deferred.
The implementation sources are [reading.css](../web/styles/reading.css) and [reading.ts](../web/scripts/reading.ts).
Bundled font licensing remains separate under `../web/fonts/JetBrainsMono-OFL.txt`.

## Accessibility & Inclusion

Preserve keyboard navigation, visible focus, the skip link, accessible button names and announced
copy results. Keep wide reference tables independently scrollable with keyboard access. Mobile
theme controls and touch copy controls use 44px targets; mobile navigation rows also use 44px.
Respect reduced-motion preferences. These are implemented requirements, not a certification claim.

<!-- EOF -->

