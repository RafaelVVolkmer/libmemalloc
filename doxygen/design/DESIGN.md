---
name: libmemalloc documentation
description: Doxygen Awesome with the libmemalloc mascot typography and palette.
colors:
  paper: "#ffffff"
  ink: "#262b44"
  primary: "#124e89"
  muted: "#5a6988"
  surface: "#f3f5f9"
  line: "#c0cbdc"
  purple: "#68386c"
  dark-paper: "#1c1d1f"
  dark-surface: "#252628"
  dark-ink: "#e7e9ed"
  dark-muted: "#adb3bd"
  dark-primary: "#9cbfe0"
  warm: "#feae34"
  code-background: "#2e3440"
  code-foreground: "#d8dee9"
  code-comment: "#a3adbf"
  code-string: "#a3be8c"
  code-link: "#88c0d0"
  code-keyword: "#81a1c1"
  code-type: "#8fbcbb"
  code-highlight: "#eceff4"
  code-border: "#4c566a"
  code-control: "#3b4252"
  code-hover: "#434c5e"
  code-number: "#bb9ab6"
typography:
  branding:
    fontFamily: '"Nunito Sans", "Segoe UI", sans-serif'
    fontSize: "24px"
    fontWeight: 700
  caption:
    fontFamily: '"Nunito Sans", "Segoe UI", sans-serif'
    fontSize: "12px"
  headline:
    fontFamily: '"Nunito Sans", "Segoe UI", sans-serif'
    fontWeight: 700
  body:
    fontFamily: '"Nunito Sans", "Segoe UI", sans-serif'
    fontSize: "16px"
    lineHeight: 1.7
    fontWeight: 400
  code:
    fontFamily: '"JetBrains Mono", ui-monospace, monospace'
    fontSize: "14px"
rounded:
  small: "5px"
  medium: "8px"
  large: "10px"
spacing:
  small: "5px"
  medium: "10px"
  large: "16px"
  xlarge: "20px"
---

<!-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com> -->
<!-- SPDX-License-Identifier: GPL-3.0-only -->

# Design System: libmemalloc documentation

## Direction

Use Doxygen Awesome as the component and layout foundation, with the identity in the
[image guide](../../assets/images/README.md). This is a reading interface for project documents
and C API references. Preserve authored content, navigation, search and original penguin artwork.
The header and SVG favicon share a mascot-only copy derived during each publication build.
Remove the trailing wordmark layers from the original SVG and use its square `-28 28 720 720` viewport;
retain the full original for the home page. The subtitle is “The Magic of Memory Transmutation”.
Show the `PROJECT_NUMBER` value, currently `0.0.0-alpha`, next to the project name.

## Typography and color

Self-host Nunito Sans Regular and Bold, using Bold for headings and the project name.
Reserve JetBrains Mono for code and API signatures. Both fonts retain their OFL notices.
Do not uppercase document titles or force prose onto a character grid.

Use the guide's Endesga 32 blue and gray-blue for the light interface, with white paper and
light derived surfaces. Dark mode uses neutral graphite paper and surfaces, soft white text,
and a muted blue link color. Keep blue and purple out of the dark page backgrounds.
Semantic warnings and notes retain the distinct status colors and labels from Doxygen Awesome.

Code blocks use the locally bundled Nord Highlight.js theme in both light and dark mode,
with equivalent tokens for native Doxygen fragments. Nord's Polar Night background (`#2E3440`),
Snow Storm text (`#D8DEE9`), Frost keywords and Aurora strings/numbers remain independent of
page colors. Comments and directives use brighter variants for readable contrast. Inline
code keeps the surrounding page's surface treatment.
Topics, Files and Functions listings also use page surfaces and readable page text/link colors;
reserve Nord surfaces for code blocks and detailed API signatures.

## Layout and components

Keep the wide 1200px content cap and the 335px sidebar from Doxygen Awesome, spacing, rounded corners,
search, tables and API panels. The sidebar header reserves 150px for branding and search.
At 1200px and above, keep the page index open in a 260px right rail with independent scrolling.
Below that width, use an expandable section index inside the document. Reuse authored indexes;
otherwise derive a hierarchical list of H2/H3 headings. Do not duplicate the index.
The mobile index expands in the page flow without nested scroll areas.
The browser title is exactly `libmemalloc`; document headings retain their descriptive titles.
Use a 60px reading toolbar with separate 44px buttons for the navigation rail and page outline,
plus the theme control. Desktop panel choices persist independently. Collapsed panels release
their content space; their controls stay reachable. On compact layouts, menus expand in page flow.
The document uses the browser's single vertical scrollbar. Only long open rails scroll independently;
their thin scrollbar becomes visible on hover/focus. Never hide overflowing content to conceal a bar.
Retain the generated attribution footer and navigation synchronization control's hidden state.
Use a GitHub Corners link at the bottom right, pointing to the libmemalloc repository. Keep
its accessible name, keyboard focus and 64px desktop/48px mobile target; it works without JavaScript.
Use the upstream Octocat wave on hover and keyboard focus, disabled when reduced motion is requested.
Horizontal separators and the page-title rule stop at the content insets.

The 767px mobile boundary follows upstream. The header stays sticky, the navigation menu has
a bounded scroll area, and heading anchors clear the header. Wide reference tables scroll
inside keyboard-focusable regions. Theme controls and touch copy controls use 44px targets.

Keep the keyboard skip link, visible focus, explicit button names and copy result announcements.
Copy controls appear on hover/focus and remain visible on touch devices. Clipboard failure
selects the code for manual copying. Reduced motion disables copy-control transitions.
Theme follows system preference until the reader explicitly chooses light or dark.

## Diagrams and code

Render Mermaid as SVG in the browser. Nodes, labels and connectors follow the brand palette
in both themes, including SVG text spans and HTML labels; the canvas stays transparent.
Use one keyboard-accessible scroll container per diagram, only when its content overflows.
Inline native Graphviz diagrams during publication, preserving links, node relationships and layout,
with unique SVG IDs. Their text, surfaces and edges share the Mermaid palette. Include text alternatives
and keyboard-operable graph disclosures. Respect forced colors and reduced motion.
Do not convert diagrams into ASCII. The HTML build requires no Node.js diagram postprocessor.

Highlight.js colors only recognized, explicitly labeled code blocks with Nord, matching native
Doxygen fragments. Rendering diagrams and highlighting require the pinned
local versioned assets; literal examples remain readable if highlighting cannot load.
Ordinary examples and inline code wrap visually, preserving the literal copied source.
Box-drawing diagrams retain their columns and may scroll horizontally. Tables use one outer
scroll region instead of separate scrolling table bodies.

Source of truth: [reading.css](../web/styles/reading.css), [libmemalloc.css](../web/styles/libmemalloc.css),
[reading.ts](../web/scripts/reading.ts). Full-site integration guidance will accompany the deferred renderer.

<!-- EOF -->

