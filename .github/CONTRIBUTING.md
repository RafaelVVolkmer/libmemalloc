<!--
SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: MIT
-->

# 🤝 Contributing to libmemalloc

Thank you for considering a contribution to **libmemalloc**! 🎉  
This document describes the workflow, coding style, and expectations when opening issues, discussions, or pull requests.

The goals are:

- predictable workflow  
- easy review  
- clean and auditable history  

---

## 1. 🏁 Getting Started

libmemalloc uses:

- **GitHub Issues** for bugs, feature requests and some documentation problems;
- **GitHub Discussions** for open-ended questions and design/usage talks;
- **Pull Requests** for code and documentation changes.

### 🐛 Reporting bugs

Please open a **GitHub Issue** and include:

- libmemalloc version (tag/commit),
- OS / toolchain (compiler, version, C standard if relevant),
- steps to reproduce (minimal if possible),
- expected vs. actual behavior,
- any relevant logs (build output, test logs, backtraces, sanitizer output, etc.).

When creating a bug issue, **please use the “Bug report” template** provided under
`.github/ISSUE_TEMPLATE/bug_report.md` (it appears automatically when you
click **New issue → Bug report**).

That template mirrors the information above and also asks for:

- build / toolchain environment,
- libmemalloc configuration (strategy, GC, logging),
- reproducibility and severity,
- an optional DCO `Signed-off-by` line.

Issues that don’t follow the template might be sent back for clarification.

### 💡 Proposing features

Open a **Feature Request** issue and describe:

- the problem you are trying to solve,
- what API/behavior you have in mind,
- impact on compatibility (breaking change or not),
- any rough design ideas or constraints.

For feature requests, **please use the “Feature request” issue template**  
(`.github/ISSUE_TEMPLATE/feature_request.md`). It guides you through:

- problem / motivation and concrete use cases,
- proposed API or configuration,
- expected API/ABI and performance impact,
- current libmemalloc configuration and environment.

For larger or potentially disruptive changes, consider opening a **Discussion**
first (see below) to align expectations before you start coding.

### 📚 Documentation issues

If you find a problem in the documentation (missing, unclear, outdated, typo, etc.):

- use the **“Documentation Issue”** template  
  (`.github/ISSUE_TEMPLATE/docs_issue.md`);

and describe:

- which file/section is affected,
- what is wrong or unclear,
- what you would expect instead.

If you already know how to fix it, you can open a PR directly and reference
the doc issue in the PR description.

### ❓ Questions and Discussions

For general **questions**, ideas, and design discussions (for example:  
“Which strategy is better for this workload?”, “How should I integrate
libmemalloc into X?”):

- prefer opening a **GitHub Discussion** in the repository’s *Discussions* tab;
- use the most appropriate category (e.g., “Q&A”, “Ideas”, etc.).

There is also a **“Questions and Help”** issue template
(`.github/ISSUE_TEMPLATE/question_help.md`) for cases where your question
is very close to a bug report or concrete feature request, but in most cases
the maintainer may redirect broad questions to Discussions.

The `config.yml` under `.github/ISSUE_TEMPLATE/` is configured to:

- disable completely blank issues (`blank_issues_enabled: false`);
- expose contact links such as:
  - **“Report a security vulnerability”** (private e-mail);
  - **“Questions and general discussion”** (link to Discussions).

---

## 2. 🔄 Development Workflow

### 🌿 Branches

This repository uses a GitFlow-inspired `main` / `develop` model:

- `main`: stable branch for tagged releases.
- `develop`: integration branch for new features and fixes.

For an overview of this style of workflow, see Atlassian’s guide:  
**Gitflow Workflow** –  
[Gitflow Workflow (Atlassian)](https://www-atlassian-com.translate.goog/git/tutorials/comparing-workflows/gitflow-workflow?_x_tr_sl=en&_x_tr_tl=pt&_x_tr_hl=pt&_x_tr_pto=tc)

To work on a change:

1. **Fork** the repository (or create a branch directly if you have access).
2. Create a topic branch off `develop`:

       git checkout develop
       git pull origin develop

       # Example branch names:
       git checkout -b feat/allocator-bitmap-free-list
       git checkout -b fix/leak-on-failed-realloc
       git checkout -b chore/ci-refactor
       git checkout -b docs/update-readme

   Branch names should follow the **conventional-branch** naming convention,
   which extends **Conventional Commits** to branches. In practice, this means:

   - start with a Conventional Commits style type: `feat`, `fix`, `chore`,
     `docs`, `refactor`, `test`, etc.;
   - optionally include a scope;
   - use short, kebab-cased descriptions.

   See:

   - **Conventional Branch specification:**  
     [Conventional Branch](https://conventional-branch.github.io)  
   - **Conventional Commits specification:**  
     [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

3. Commit your work to this branch.
4. Before opening a PR, rebase on the latest `develop`:

       git fetch origin
       git rebase origin/develop

5. Open a **Pull Request** targeting `develop`.

Small, focused branches (one logical change per branch) are strongly preferred.

---

## 3. 📐 Coding Guidelines

### 🗣️ Language and style

- Code is written in **standard C99**.
- Avoid compiler-specific extensions in the **public API**.
- Keep the code portable whenever feasible.

Before committing, please run the style / lint tools provided by the repository (for example):

       ./scripts/style_check.sh

(See the `README.md` for up-to-date instructions and additional tooling.)

### 🗂️ Project layout

- Public headers live in `inc/`.
- Implementation files live in `src/`.
- Do not expose internal details in public headers.
- Prefer `static` functions for module-internal helpers.
- Keep naming, comments and structure consistent with the existing code.

---

## 4. 🧾 Commit Messages

Good commit messages make review and `git bisect` much easier.

This project follows a **Conventional Commits–like** format:

    type(scope): short imperative summary

    [optional body explaining what/why, not only how]

Examples:

    feat(allocator): add bitmap-based free list
    fix(logs): make variadic macros C99-safe under Docker toolchain
    chore(build): refactor CMake targets for tests
    docs(readme): add usage examples and build instructions

Guidelines:

- Use English.
- Use the imperative mood: `add`, `fix`, `refactor`, `remove`, …  
- Group logical changes into separate commits.
- Avoid noisy commits like `wip`, `fix stuff`, `more changes` in the final history –  
  use `git rebase -i` to clean up before opening a PR.

For more details on the commit format, see the **Conventional Commits** specification:  
[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

### ✍️ DCO / Signed-off-by

Using a Developer Certificate of Origin line is strongly recommended:

<pre><code>git commit -s -m "feat(allocator): add bitmap-based free list"</code></pre>

This appends a `Signed-off-by` trailer to the commit message.

The Pull Request template also contains a **`Signed-off-by` field** that should be
filled with your own name and email, matching the DCO line in your commits.

### 🔐 GPG-signed commits and tags (recommended)

Using GPG-signed commits and tags is **strongly encouraged** for this project.

Signing helps to:

- prove that a commit or tag was really created by the stated author;
- protect the history from identity spoofing (`git config user.name/user.email` is easy to fake);
- improve traceability and auditability of releases and bug fixes.

If you have a GPG key configured with GitHub, please sign your work with:

<pre><code>git commit -S -m "feat(allocator): add bitmap-based free list"</code></pre>

and, for releases or important milestones:

<pre><code>git tag -s vX.Y.Z -m "libmemalloc vX.Y.Z"</code></pre>

If you are new to GPG and signed commits, you may find these resources useful:

- **Pro Git – Signing Your Work** (chapter explaining GPG-signed Git commits):  
  [Signing Your Work – Pro Git](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)  
- **GitHub Docs – About commit signature verification** (how GitHub shows verified signatures):  
  [About commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)

Unsigned commits are still accepted, but **signed commits and tags are preferred**
and considered best practice for contributors who are comfortable with GPG.

---

## 5. 🧪 Build and Test

Before opening a PR, please ensure the project builds cleanly and that tests pass.

### 🏗️ Local builds

Convenience scripts are available under `scripts/`. For example:

       ./scripts/build.sh debug
       ./scripts/build.sh release

If you prefer building via Docker (when supported):

       ./scripts/build.sh release --docker --platform linux/amd64

### ✅ Tests

- Run the test suite as documented in `README.md`
  (e.g., via `ctest` in the `build` directory or via a dedicated script).
- When adding or modifying features, update or extend the test coverage accordingly.
- PRs that break existing tests or add untested functionality may be asked to
  include appropriate tests before being merged.

---

## 6. 📚 Documentation

- When you change the **public API**, update:
  - Doxygen-style comments in public headers,
  - relevant sections in `README.md` or other docs.
- Comments should state **intent and contract** (pre-/post-conditions), not just restate the obvious.

If the project publishes Doxygen documentation (for example via GitHub Pages),
please keep function and struct descriptions in sync with real behavior.

---

## 7. 🔀 Pull Request Guidelines

When opening a Pull Request, please:

- Use a clear title in the same spirit as a good commit summary.
- In the description, include:
  - context (which problem you are solving),
  - a short explanation of the proposed solution,
  - impact on API / compatibility,
  - how to test (commands, main cases).

All Pull Requests are expected to **follow the PR template**
(`.github/pull_request_template.md`).  
When GitHub pre-fills the description:

- keep the sections provided by the template,
- fill in the relevant fields (environment, tests, API/ABI/perf impact, DCO line),
- do not remove checklists unless they are clearly not applicable.

Smaller, focused PRs are much easier to review and more likely to be merged quickly.

If your PR is not ready for review yet, mark it as a **Draft**.

---

## 8. 🛡️ Security

If you believe you have found a **security issue** (for example: heap corruption,
use-after-free, double free, or other potentially exploitable behavior):

- **Do not open a public GitHub issue initially.**
- Instead, please send a private report to:

       rafael.v.volkmer@gmail.com

You will also find a **“Report a security vulnerability”** contact card when you
click **New issue**; it points to the same private channel.

Include:

- a description of the issue,
- steps or a minimal program to reproduce,
- any analysis or PoC you are comfortable sharing.

The maintainer will:

- investigate the issue,
- coordinate a fix,
- discuss responsible disclosure and timing, if relevant.

---

## 9. 📜 License

By contributing to this repository, you agree that your contributions will
be licensed under the terms specified in the project’s `LICENSE` file.

---

Thank you for helping make **libmemalloc** better! 🚀
