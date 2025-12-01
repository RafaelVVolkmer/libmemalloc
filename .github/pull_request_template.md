<!--
SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: MIT
-->

## 📝 Summary

Describe the purpose of this Pull Request in 1–3 sentences.

- What problem does it solve?
- Why is this change needed?

## 🧱 Type of change

Select all that apply:

- [ ] feat: New feature
- [ ] fix: Bug fix
- [ ] chore: Build / tooling / CI
- [ ] docs: Documentation only
- [ ] refactor: Code refactor without behavior change
- [ ] perf: Performance optimization
- [ ] test: Tests only

## 🔗 Related Issues

- Closes #ISSUE_ID  
- Related to #ISSUE_ID  

(Use `Closes #...` to auto-close issues when the PR is merged.)

## 🏗️ Build / Toolchain Environment

Please describe **where** this was developed and built (target + host):

- libmemalloc version (tag/commit): `vX.Y.ZZ` or `<commit-hash>`
- Target architecture: (e.g. `x86_64`, `armv7`, `aarch64`)
- Target CPU / SoC / board: (e.g. `Intel i7-8650U`, `TI AM6232`, `STM32MP135`, etc.)
- Kernel / OS and version: (e.g. `Linux 6.11.5 on Ubuntu 24.04`, `Windows 11 23H2`)
- Host compiler and version: (e.g. `gcc 14.1`, `clang 18.1`)
- C standard used: (e.g. `-std=c99`)
- Doxygen version used (if relevant):
- Valgrind version used (if used):
- gcov / coverage tool version used (if used):

Build method:

- [ ] `./build.sh`
- [ ] CMake manual invocation
- [ ] Docker
- [ ] Other (describe):

## 💡 Implementation Notes

- Briefly describe how the change is implemented.
- Mention any important design decisions or trade-offs.
- Note any changes in allocator behavior, GC, logging, or public API.

## 🔁 API / ABI Compatibility

Does this change affect the public API or ABI?

- [ ] No behavior or signature changes.
- [ ] API changed but backwards compatible (additions only).
- [ ] Breaking change (callers may need code changes).

If there is any API/ABI impact, please explain:

- Impacted functions/types:
- Expected migration steps for users:

## 🚀 Performance Impact

If relevant, describe performance expectations and/or measurements:

- [ ] No significant performance impact expected.
- [ ] Performance-sensitive change (allocator path, GC, etc.).

If you ran benchmarks, summarize them here (latency/throughput, before vs after):

<pre><code>
# example
benchmark_something_before:  X ops/s
benchmark_something_after:   Y ops/s
</code></pre>

## 🛡️ Security / Memory-Safety Impact

Does this PR touch memory management, pointer arithmetic, or GC logic?

- [ ] No (pure docs / build / tests / logging).
- [ ] Yes, allocator / GC / low-level memory paths.

If **yes**, briefly describe:

- What risks are mitigated or introduced?
- How did you validate that no new UAF/double-free/out-of-bounds was introduced?

## 🧪 Testing

Please describe how you tested this change:

- [ ] `./scripts/build.sh debug`
- [ ] `./scripts/build.sh release`
- [ ] Unit tests (ctest or equivalent)
- [ ] Additional manual tests (describe below)

Details (commands, platforms, special tests):

<pre><code>
# examples
./scripts/build.sh debug
ctest --output-on-failure
./bin/Release/some_custom_test
</code></pre>

If this change could affect memory safety (allocation/free paths, GC, etc.),
please mention any sanitizer or fuzzing runs you did.

## 📚 Documentation

- [ ] Public headers updated (if API changed)
- [ ] README / docs updated
- [ ] Doxygen comments updated where relevant

## ✅ Checklist

- [ ] My branch name follows the conventional-branch style  
      (e.g. `feat/allocator-bitmap-free-list`, `fix/leak-on-failed-realloc`).
- [ ] My commits follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) style.
- [ ] I have run the style/lint tools (e.g. `./scripts/style_check.sh`).
- [ ] I have considered signing my commits/tags with GPG  
      (recommended; see [Signing Your Work](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)).

## ✍️ Signed-off-by (DCO)

By filling the line below, you certify that your contribution complies with
the Developer Certificate of Origin (DCO). Please replace with **your own**
name and email:

<pre><code>Signed-off-by: &lt;Your Name&gt; &lt;your.email@example.com&gt;</code></pre>
