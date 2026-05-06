<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Commit Message Guide

> [!NOTE]
> Reference specification:
>
> This commit guideline is based on Conventional Commits, version 1.0.0:
>
> - [Conventional Commits 1.0.0][conventional-commits-url]

---

## Message Format

A Conventional Commit message uses the following structure:

```bash
<type>[optional scope][optional !]: <description>

[optional body]

[optional footer(s)]

[optional signature(s)]
```

The commit prefix must include a `type`, may include a `scope`, may include
`!` for a breaking change, and must be followed by `:` before the short
description.

> [!IMPORTANT]
> Commit message lines must not exceed **70 characters**.
>
> This applies to the subject, body, footers, and signatures.
>
> Long academic references in `Theory-reference:` trailers may be wrapped onto
> continuation lines when needed.

Examples:

```text
fix(allocator): reject invalid free list state
feat(gc): add runtime state machine
docs(readme): document build requirements
ci(scorecard): add OpenSSF Scorecard workflow
feat(api)!: rename public allocation entry point
```

---

## Type

The `type` describes the kind of change being made.

The Conventional Commits specification gives direct SemVer meaning to `fix`,
`feat`, and breaking-change markers. Other types are allowed and should be used
consistently by the project.

| Type       | Use when                                                                                                   | SemVer impact by default |
| ---------- | ---------------------------------------------------------------------------------------------------------- | ------------------------ |
| `feat`     | Adding a new feature or capability.                                                                        | `MINOR`                  |
| `fix`      | Fixing a bug or incorrect behavior.                                                                        | `PATCH`                  |
| `build`    | Changing build system, compiler flags, packaging, dependency metadata, or generated build files.           | None                     |
| `chore`    | Performing repository maintenance with no direct source, test, build, or documentation meaning.            | None                     |
| `ci`       | Changing CI/CD workflows, GitHub Actions, automation, runners, or pipeline configuration.                  | None                     |
| `docs`     | Changing documentation only.                                                                               | None                     |
| `style`    | Changing formatting, whitespace, spelling style, lint formatting, or code layout without behavior changes. | None                     |
| `refactor` | Reorganizing code without fixing a bug or adding a feature.                                                | None                     |
| `perf`     | Improving performance without changing expected behavior.                                                  | None                     |
| `test`     | Adding, updating, or refactoring tests.                                                                    | None                     |
| `revert`   | Reverting one or more previous commits.                                                                    | Tooling-dependent        |

Use this decision table when selecting the type:

| Question                                                                                  | Recommended type              |
| ----------------------------------------------------------------------------------------- | ----------------------------- |
| Does this fix incorrect behavior?                                                         | `fix`                         |
| Does this add a new user-visible or project-visible capability?                           | `feat`                        |
| Does this break public API, ABI, CLI, configuration, file format, or documented behavior? | Add `!` or `BREAKING CHANGE:` |
| Does this only change documentation?                                                      | `docs`                        |
| Does this only change tests?                                                              | `test`                        |
| Does this only change CI/CD?                                                              | `ci`                          |
| Does this only change build logic, toolchain settings, packaging, or dependency metadata? | `build`                       |
| Does this only change formatting or lint style without behavior changes?                  | `style`                       |
| Does this improve runtime or memory performance without changing behavior?                | `perf`                        |
| Does this restructure implementation without adding features or fixing bugs?              | `refactor`                    |
| Is this generic repository maintenance?                                                   | `chore`                       |
| Does this undo a previous commit?                                                         | `revert`                      |

When a change appears to match more than one type, prefer splitting it into
multiple commits.

---

## Scope

The `scope` is optional. When used, it appears inside parentheses after the
type:

```text
<type>(<scope>): <description>
```

A scope should be a small, stable, conceptual noun that identifies the affected
area of the codebase.

Good examples:

```text
fix(allocator): handle zero-sized allocation consistently
feat(gc): add conservative root scanner
docs(security): document vulnerability reporting policy
ci(scorecard): add OpenSSF Scorecard workflow
build(cmake): enable strict warning options
test(overflow): add size boundary cases
```

Avoid overly specific file-path scopes unless the file itself is the conceptual
area being changed.

Avoid:

```text
fix(src/mem_alloc.c): handle zero-sized allocation
docs(file): update docs
feat(random): add runtime state machine
```

Prefer:

```text
fix(allocator): handle zero-sized allocation
docs(readme): update repository overview
feat(gc): add runtime state machine
```

Use the smallest stable conceptual area that explains the change.

| Situation                | Scope style      | Examples                                                     |
| ------------------------ | ---------------- | ------------------------------------------------------------ |
| Core allocator change    | subsystem        | `allocator`, `arena`, `heap`, `chunk`, `bin`                 |
| Garbage collector change | subsystem        | `gc`, `scanner`, `tracer`, `barrier`                         |
| Public contract change   | contract         | `api`, `abi`, `config`                                       |
| Header or macro change   | component        | `headers`, `env`, `assert`, `log`                            |
| Documentation change     | document area    | `readme`, `security`, `contributing`, `conduct`, `changelog` |
| Test change              | test area        | `tests`, `overflow`, `allocator`, `gc`                       |
| Build change             | build tool       | `build`, `cmake`, `make`, `toolchain`                        |
| CI change                | automation area  | `ci`, `github-actions`, `scorecard`, `slsa`                  |
| Compliance change        | compliance topic | `spdx`, `sbom`, `reuse`, `slsa`, `scorecard`                 |
| Whole-repository change  | repository-level | `repo`, `project`, `treewide`                                |

---

## Description

The description is the short summary after `:`.

Rules:

- use imperative mood;
- keep the subject line under **70 characters**;
- do not end the subject with a period;
- describe what the commit does, not how it was implemented;
- prefer a lowercase verb after `:` unless a proper noun is required.

Good examples:

```text
feat(gc): add Immix-inspired line allocator
fix(heap): reject corrupted block metadata
docs(conduct): document private incident reporting
```

Avoid:

```text
feat(gc): added a new allocator.
fix(heap): this fixes a bug in the heap implementation
docs: update file
```

---

## Body

The body explains why the change exists, what changed, and what impact it has.

For non-trivial commits, use the following structure:

```text
Motivation: <why this change is needed>

Details: <what changed>

Impact: <compatibility, testing, migration, performance, or release impact>
```

Each body line must be wrapped at **70 characters**.

Recommended example:

```text
Motivation: the GC needs a heap layout that improves locality while
limiting fragmentation in long-running C workloads.

Details: add block metadata, line mark bits, and allocation search
over reusable partially-free regions.

Impact: no public allocation API changes.
```

Use the body for:

- architectural decisions;
- compatibility notes;
- security reasoning;
- performance trade-offs;
- testing strategy;
- migration impact;
- academic or theoretical motivation.

Small commits may omit the body when the subject is already clear.

---

## Footer

Footers appear after a blank line following the body.

Footers are used for structured metadata such as issues, reviews,
breaking-change notices, academic references, and release notes.

Each footer line must follow a Git-trailer-like format:

```text
Token: value
```

Footer lines should stay below **70 characters** whenever possible.

The `Theory-reference:` footer is allowed to wrap onto continuation lines
because APA-style references and DOI metadata can be longer than ordinary
trailers.

Recommended footers:

| Footer              | Use when                                                                                           |
| ------------------- | -------------------------------------------------------------------------------------------------- |
| `Refs:`             | Linking issues, pull requests, discussions, tickets, commits, or external tracking references.     |
| `Reviewed-by:`      | Recording a reviewer who reviewed and approved the change.                                         |
| `Theory-reference:` | Citing an academic, theoretical, standards, or formal technical source that influenced the change. |
| `BREAKING CHANGE:`  | Documenting a backward-incompatible change.                                                        |
| `BREAKING-CHANGE:`  | Alternative token for `BREAKING CHANGE:`.                                                          |

Examples:

```text
Refs: #123
Refs: https://github.com/RafaelVVolkmer/libmemalloc/issues/123
Reviewed-by: Jane Doe <jane@example.com>
```

Use `Refs:` for implementation tracking, issue links, pull requests, or related
discussion.

Use `Reviewed-by:` only when the named person actually reviewed the change.

Use `Theory-reference:` when the commit is based on a paper, book, standard,
specification, technical report, or formal theoretical source.

Preferred APA-style format:

```text
Theory-reference: Author, A. A., & Author, B. B. (Year). Short title.
  Venue. DOI: <doi>
```

Example with DOI:

```text
Theory-reference: Blackburn, S. M., & McKinley, K. S. (2008).
  Immix. PLDI. DOI: 10.1145/1375581.1375586
```

Example without DOI:

```text
Theory-reference: Boehm, H. J. (n.d.). Conservative garbage
  collection. URL: https://www.hboehm.info/gc/gcdescr.html
```

Multiple academic sources may be listed with repeated trailers:

```text
Theory-reference: Blackburn, S. M., & McKinley, K. S. (2008).
  Immix. PLDI. DOI: 10.1145/1375581.1375586
Theory-reference: Bacon, D. F., Cheng, P., & Rajan, V. T. (2004).
  A unified theory of garbage collection. OOPSLA.
  DOI: 10.1145/1028976.1028982
```

Breaking changes may be represented with `!` in the prefix:

```text
feat(api)!: rename MEM_alloc to MEM_malloc
```

Or with a footer:

```text
feat(api): rename allocation entry point

BREAKING CHANGE: MEM_alloc was renamed to MEM_malloc.
```

Both forms indicate a major-version impact.

The `!` must appear immediately before the `:`.

The `BREAKING CHANGE:` footer must use uppercase text.

The footer token `BREAKING-CHANGE:` is also valid and synonymous with
`BREAKING CHANGE:`.

---

## Signature

Signatures appear at the end of the commit message, after ordinary footers.

The required DCO signature trailer is:

```text
Signed-off-by: Full Name <email@example.com>
```

For this repository, commits authored by the project maintainer should use:

```text
Signed-off-by: Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
```

Use `git commit -s` to append the `Signed-off-by` trailer automatically:

```sh
git commit -s -m "feat(scope): add short imperative summary"
```

To combine DCO sign-off with a cryptographic commit signature, use both `-s`
and `-S`:

```sh
git commit -s -S -m "fix(allocator): validate free list links"
```

DCO sign-off and GPG signing solve different problems:

| Mechanism             | Purpose                                                                       |
| --------------------- | ----------------------------------------------------------------------------- |
| `Signed-off-by`       | Records contributor certification and DCO intent.                             |
| GPG/OpenPGP signature | Cryptographically verifies the commit signer.                                 |
| Cosign signature      | Cryptographically verifies release artifacts, SBOMs, images, or attestations. |

---

## Recommended Commit Template

```text
<type>(<scope>): <imperative summary>

Motivation: <why this change is needed>

Details: <what changed>

Impact: <compatibility, testing, migration, performance, or release impact>

Refs: <issue, pull request, discussion, or external tracking reference>
Reviewed-by: <reviewer name> <reviewer@example.com>
Theory-reference: <APA-style short reference>. DOI: <doi>
Signed-off-by: Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
```

Rules:

- keep every commit message line under **70 characters**;
- allow `Theory-reference:` to wrap onto continuation lines when needed;
- keep the subject short and imperative;
- prefer one logical change per commit;
- use `Motivation`, `Details`, and `Impact` for non-trivial commits;
- use `Refs:` for related issues, pull requests, and discussions;
- use `Reviewed-by:` only for real review attribution;
- use `Theory-reference:` only for academic or formal technical sources;
- use `Signed-off-by` for DCO-style commits;
- prefer cryptographically signed commits for trusted branches;
- sign release tags;
- sign release artifacts, checksums, SBOMs, and container images with Cosign
  when they are published;
- add `BREAKING CHANGE:` when the public contract changes.

---

## Example

```text
feat(gc): add Immix-inspired line allocator

Motivation: the GC needs a heap layout that improves locality
while limiting fragmentation in long-running C workloads.

Details: add block metadata, line mark bits, and allocation
search over reusable partially-free regions.

Impact: no public allocation API changes.

Refs: #42
Reviewed-by: Jane Doe <jane@example.com>
Theory-reference: Blackburn, S. M., & McKinley, K. S. (2008).
  Immix. PLDI. DOI: 10.1145/1375581.1375586
Signed-off-by: Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
```

---

## Commit Message Checklist

Before pushing commits, verify:

- [ ] the commit uses a valid Conventional Commit `type`;
- [ ] the scope is stable, meaningful, and not an unnecessary file path;
- [ ] the description is imperative and under 70 characters;
- [ ] body lines are wrapped at 70 characters;
- [ ] non-trivial commits include `Motivation`, `Details`, and `Impact`;
- [ ] `Refs:` points to related issues, PRs, discussions, or tickets;
- [ ] `Reviewed-by:` is used only for real review attribution;
- [ ] `Theory-reference:` uses compact APA style with DOI or URL;
- [ ] `Theory-reference:` is wrapped on continuation lines if needed;
- [ ] breaking changes use `!` or `BREAKING CHANGE:`;
- [ ] every non-merge commit includes `Signed-off-by`.

---

<!-- ======================================================================= -->
<!-- References                                                              -->
<!-- ======================================================================= -->

[conventional-commits-url]: https://www.conventionalcommits.org

<!-- EOF -->
