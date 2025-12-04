<!--
SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: MIT
-->

---
name: 🐛 Bug report
about: Create a report to help improve libmemalloc
title: "[BUG] "
labels: ["bug"]
assignees: []
---

## 📝 Description

A clear and concise description of the bug.

What is going wrong? In what general situation (startup, heavy load, shutdown, specific API, etc.)?

---

## 🏗️ Build / Toolchain Environment

Please describe **where** this was developed and built (target + host):

- libmemalloc version (tag/commit): `vX.Y.ZZ` or `<commit-hash>`
- Build type: `Debug` / `Release`
- Target architecture: (e.g. `x86_64`, `armv7`, `aarch64`)
- Target CPU / SoC / board: (e.g. `Intel i7-8650U`, `TI AM6232`, `STM32MP135`, etc.)
- Kernel / OS and version where the bug occurs:
  - e.g. `Linux 6.11.5 on Ubuntu 24.04`, `Windows 11 23H2`
- Host compiler and version: (e.g. `gcc 14.1`, `clang 18.1`)
- C standard used: (e.g. `-std=c99`)
- Doxygen version: (if relevant)
- Valgrind version: (if used)
- gcov / coverage tool version: (if used)

Build method:

- [ ] `./build.sh`
- [ ] CMake manual invocation
- [ ] Docker
- [ ] Other (describe):

---

## ⚙️ libmemalloc Configuration

If you have changed any defaults, please describe:

- Allocation strategy in use:
  - e.g. `FIRST_FIT`, `NEXT_FIT`, `BEST_FIT`, segregated lists, etc.
- GC / background collection:
  - [ ] Disabled (default)
  - [ ] Enabled (describe triggers/intervals if relevant)
- Logging:
  - Log level: `ERROR` / `WARN` / `INFO` / `DEBUG`
  - Any custom log sink or integration?
- Non-default compile-time options / macros:
  - e.g. special alignment, debug checks, extra asserts, etc.

---

## 🔁 Steps to Reproduce

1. …
2. …
3. …

If possible, include a **minimal** C snippet that reproduces the issue:

<pre><code class="language-c">
// minimal example here
</code></pre>

---

## ✅ Expected Behavior

What you expected to happen.

---

## ❌ Actual Behavior

What actually happened (logs, wrong results, crashes, etc.).

If there are crashes, please include:

- Backtrace (e.g. `gdb` or `lldb` output)
- Any sanitizer output (ASan/UBSan/etc.) if used
- Relevant libmemalloc logs (especially at WARN/ERROR/DEBUG levels)

---

## 🎯 Reproducibility & Severity

- How often does it happen?
  - [ ] Always reproducible
  - [ ] Sometimes
  - [ ] Rarely / hard to reproduce

- Impact:
  - [ ] Cosmetic / logging only
  - [ ] Incorrect allocation behavior (wrong size, wrong pointer, etc.)
  - [ ] Memory leak
  - [ ] Crash / abort
  - [ ] Potential security impact (use-after-free, OOB, double free, etc.)

If you checked **security impact**, please briefly explain why:

---

## ⏪ Regression?

- [ ] This worked in a previous version
- [ ] Not sure / first time using this feature

If it is a regression, please specify:

- Known good version:
- First known bad version:

---

## 📎 Additional Context

Add any other context, logs, or configuration details that might be relevant:

- Integrating with which kind of application? (e.g. game server, embedded system, test harness, etc.)
- Any interaction with other allocators (jemalloc, tcmalloc, etc.)?
- Anything special about threading, signals, or fork/exec usage?

---

## ✍️ Signed-off-by (DCO)

If you are also contributing patches/fixes related to this bug report and want
to comply with the Developer Certificate of Origin, please fill in the line
below with **your own** name and email:

<pre><code>Signed-off-by: &lt;Your Name&gt; &lt;your.email@example.com&gt;</code></pre>
