<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Documentation authoring and validation

Write product contracts in `specs/`, repository rules in `standards/`, acceptance steps in `procedures/` and
executable instructions in `runbooks/`. Use `reference/` for technical contracts and `assurance/` for mappings
and gaps. Update the relevant index and [playbook](../playbook.md) when adding an execution guide.

Use the [engineering review procedure](../procedures/decision-making.md) for new engineering choices.
Task inventories belong only in product SDD files; do not add them to guides, reference pages or PR templates.

Preserve requirement IDs and anchors when relocating content. Update relative Markdown and image links,
repository-root references in scripts, path filters and documentation tests. Give proposed procedures an
explicit status and keep command examples tied to implementations that exist.

<details>
<summary><strong>On this page</strong></summary>

- [Document presentation](#document-presentation)
- [Dependencies](#dependencies)
- [Validation](#validation)
- [Hosted validation and publication](#hosted-validation-and-publication)

</details>

---

## Document presentation

Follow the [C standard's presentation](../standards/c/c-code-standard.md): a license header, one title,
a short purpose statement, a collapsible **On this page** index for documents with sections, and horizontal
rules between major sections. Keep short directory indexes as compact lists or tables. Preserve existing
anchors and control IDs. Use the same heading level for the same kind of content within a document.

State requirements before rationale and examples. Identify incomplete implementation or evidence where it
changes how the reader can use the document. Link primary sources beside the claims they support. Keep
literal code, normative quantifiers and evidence limitations intact during prose editing. Write comments
and explanations in plain English; remove filler without weakening contracts.

---

## Dependencies

Use the Node and Doxygen versions from the [toolchain lock](../../tools/toolchain/lock.toml).
Install the Markdown and web graphs in the locations used by the repository checkers:

```sh
mkdir -p .cache/tools/md
cp tools/lint/code/md/package.json tools/lint/code/md/package-lock.json .cache/tools/md/
lua scripts/workspace/cache.lua npm ci --prefix .cache/tools/md --ignore-scripts
mkdir -p .cache/tools/web
cp tools/lint/code/web/package.json tools/lint/code/web/package-lock.json .cache/tools/web/
lua scripts/check/doc_tools.lua
lua scripts/workspace/cache.lua npm ci --prefix .cache/tools/web --ignore-scripts
```

Install Graphviz for native C dependency graphs; the hosted Ubuntu profile pins its package version and
digest in the same lock. APT verifies its runtime dependencies through signed repository metadata.

Install the declared Doxygen binary using the existing CI download recipe, or select an installed matching
binary with `LIBMEMALLOC_DOXYGEN`. The generator does not download dependencies. See the
[Doxygen implementation reference](../../doxygen/README.md) for configuration and output formats.

---

## Validation

Run from the repository root. Shared source checks include new working files and omit deleted files.
The explicit Markdown command below includes tracked and untracked paths. Use a clean checkout to
validate one commit independently of pending changes.

```sh
git ls-files -z --cached --others --exclude-standard -- '*.md' | \
  xargs -0 lua scripts/check/format.lua markdown \
  .cache/tools/md/node_modules/.bin/markdownlint
lua scripts/check/links.lua --offline
lua scripts/check/mermaid.lua
lua scripts/check/eof.lua
lua tests/automation/documentation/policy_test.lua
lua scripts/check/documentation.lua
lua tests/automation/workspace/changes_test.lua
lua scripts/check/c.lua
lua scripts/check/doc_examples.lua
lua scripts/check/c_documentation.lua
lua tests/automation/documentation/filter_test.lua
lua tests/automation/documentation/html_test.lua
lua tests/automation/documentation/driver_test.lua
lua scripts/documentation/main.lua eval
lua scripts/documentation/main.lua build
```

C example checks also require the selected compilers, formatter, analyzer and CMake.
The link command above checks local links; use the same command without `--offline` for external links when
network validation is required. Review Doxygen diagnostics and the generated navigation, diagrams and links.
The default HTML entry point is `.cache/docs/doxygen-build/html/index.html`.

---

## Hosted validation and publication

The [documentation workflow](../../.github/workflows/documentation.yml) runs on pull requests, merge queues,
pushes to `feature/libmemalloc-refactor` and manual requests. Its validation job checks document policy,
Markdown, local links,
Mermaid and Doxygen, then retains the generated site and diagnostics as a review artifact. Dependency installation uses
the toolchain digests and npm lock integrity; checkout pins the theme submodule to its recorded commit.

Only the separate deploy job receives `pages: write` and `id-token: write`. It consumes the accepted Pages
artifact from the same run and runs only for a push or manual request on `feature/libmemalloc-refactor`.
Configure GitHub Pages
to use Actions and protect the `github-pages` environment before the first hosted publication. PR validation
uses per-ref concurrency; deployments share a separate queue.

The workflow watches the complete repository because C sources, Lua drivers, root documents, assets and
configuration all affect the generated site. Deployment depends on the workflow's `validate` job.
The reusable spelling and prose gates run in the separate CI workflow; they are not dependencies of this deploy job.
A successful local build validates the site inputs; hosted environment
configuration and deployment require their own result.

<!-- EOF -->

