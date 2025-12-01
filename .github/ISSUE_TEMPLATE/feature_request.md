<!--
SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: MIT
-->

---
name: 💡 Feature request
about: Suggest an idea or improvement for libmemalloc
title: "[FEAT] "
labels: ["enhancement"]
assignees: []
---

## 📝 Description

A clear and concise description of the feature you would like to see.

Focus first on the **problem or limitation** you are facing, not only on the
solution you have in mind.

- What is missing today?
- In which context are you using libmemalloc (type of application, workload, etc.)?

---

## 🎯 Motivation / Use Case

Explain **why** this feature is important:

- How would it improve your project or workflow?
- Is it about safety, performance, observability, ergonomics, or something else?
- Is there any specific constraint (real-time, embedded device, memory limits, etc.)?

If possible, describe a concrete use case:

- What does your application do?
- Where would libmemalloc be used in that application?

---

## 💡 Proposed Solution

Describe the feature or behavior you would like to see:

- New API functions or configuration options?
- Changes to existing behavior or defaults?
- New allocation strategies, debug hooks, statistics, GC options, etc.?

If you have an idea of API/usage, you can sketch it here:

<pre><code class="language-c">
// example API usage (pseudo-code)
void *ptr = memalloc_alloc_special(/* ... */);
</code></pre>

This does not need to be final; it just helps to understand the direction.

---

## 🏗️ Build / Toolchain Environment (optional, but helpful)

If this feature is motivated by a specific platform or toolchain, please describe:

- libmemalloc version (tag/commit): `vX.Y.ZZ` or `<commit-hash>`
- Build type: `Debug` / `Release`
- Target architecture: (e.g. `x86_64`, `armv7`, `aarch64`)
- Target CPU / SoC / board: (e.g. `Intel i7-8650U`, `TI AM6232`, `STM32MP135`, etc.)
- Kernel / OS and version:
  - e.g. `Linux 6.11.5 on Ubuntu 24.04`, `Windows 11 23H2`
- Host compiler and version: (e.g. `gcc 14.1`, `clang 18.1`)
- C standard used: (e.g. `-std=c99`)

Build method:

- [ ] `./build.sh`
- [ ] CMake manual invocation
- [ ] Docker
- [ ] Other (describe):

---

## ⚙️ Current libmemalloc Configuration

If you have changed any defaults, please describe:

- Allocation strategy in use:
  - e.g. `FIRST_FIT`, `NEXT_FIT`, `BEST_FIT`, segregated lists, etc.
- GC / background collection:
  - [ ] Disabled (default)
  - [ ] Enabled (describe triggers/intervals if relevant)
- Logging:
  - Log level: `ERROR` / `WARN` / `INFO` / `DEBUG`
- Non-default compile-time options / macros:
  - e.g. special alignment, debug checks, extra asserts, etc.

This helps understand if the feature impacts a particular configuration.

---

## 🔄 Alternatives Considered

Have you considered any alternatives?

- Different libmemalloc configuration?
- Implementing the feature in your application instead of the allocator?
- Using another allocator or external tool?

Please describe the trade-offs and why they are not sufficient.

---

## 🔁 API / ABI Impact (expectation)

How do you expect this feature to affect the public API/ABI?

- [ ] No API changes (purely internal behavior/config)
- [ ] API extension (new functions/types, backwards compatible)
- [ ] Potentially breaking change (existing callers may need adjustments)

If you expect any API/ABI impact, describe it:

- New or changed functions/types:
- Suggested migration path for existing users:

---

## 🚀 Performance Expectations

Does this feature target performance?

- [ ] Not primarily about performance.
- [ ] Mainly about performance (latency/throughput/memory usage).

If yes, describe:

- What aspect of performance should improve?
- Under what workload pattern (many small allocs, few big ones, mixed, etc.)?

If you have any rough numbers or expectations, add them here.

---

## 📎 Additional Context

Add any other context or references that might be useful:

- Links to related issues or discussions
- Papers, blog posts, or prior art in other allocators
- Diagrams, pseudo-code, or rough design documents

---

## ✍️ Signed-off-by (DCO)

If you intend to contribute code or patches related to this feature and want
to comply with the Developer Certificate of Origin, please fill in the line
below with **your own** name and email:

<pre><code>Signed-off-by: &lt;Your Name&gt; &lt;your.email@example.com&gt;</code></pre>
