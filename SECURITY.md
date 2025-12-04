<!--
SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: MIT
-->

# Security Policy for libmemalloc 🛡️

This document describes how to report security vulnerabilities in
**libmemalloc**, which versions are supported with security fixes, and what you
can expect from the maintainer when a report is submitted.

---

## 1. Supported Versions 📦

libmemalloc is a small library and does not maintain a complex support matrix.
In general, **only the latest released version** is eligible for security
fixes.

- ✅ **Supported**: Latest tagged release on the `main`/`develop` branch  
- ⚠️ **Best-effort**: Previous release, if the issue is trivial to backport  
- ❌ **Unsupported**: Older releases, forks, and custom patches not maintained
  in the official repository

If you depend on an older version and find a security issue, you are still
encouraged to report it. However, the fix may be delivered only in a newer
release.

---

## 2. How to Report a Vulnerability 📧

Please **do not open a public GitHub issue** for potential security problems.

Instead, report vulnerabilities **privately** via email:

- **Security contact:** `rafael.v.volkmer@gmail.com`
- **Subject suggestion:** `libmemalloc: Security issue report`

When possible, include:

1. A clear description of the issue.
2. Steps to reproduce (proof-of-concept, minimal test case, or description).
3. The version or commit hash of libmemalloc you are using.
4. The expected impact (e.g., memory corruption, information leak, denial of
   service).
5. Any relevant environment details (compiler, OS, build flags, sanitizer
   reports).

If you prefer, you may also:

- Mention relevant sanitizer output (ASan, UBSan, Valgrind, etc.).
- Attach logs or backtraces, redacting sensitive information.

---

## 3. What to Expect After Reporting ⏱️

After you send a security report, you can typically expect:

1. **Acknowledgement** of the report within a reasonable time frame (usually a
   few business days).
2. An initial assessment of the issue (e.g., confirmed, needs more info, or not
   reproducible).
3. Coordination on:
   - Whether a coordinated disclosure date is needed.
   - Whether a CVE ID should be requested (for higher-impact issues).
4. Preparation of:
   - A patch and/or new release with the fix.
   - A brief description of the impact and mitigation steps.

The maintainer may request additional details to reproduce and properly
understand the vulnerability.

---

## 4. Public Disclosure 📢

Once a fix is prepared and released, details about the vulnerability may be
disclosed publicly, for example via:

- Release notes / changelog
- Git commit messages
- Security advisories (if applicable)

If you reported the issue, you may be credited in the changelog or advisory,
unless you explicitly request anonymity.

---

## 5. Non-Security Bugs 🐛

If the issue **does not** appear to be security-related (for example, a logic
bug, performance regression, or build failure), please use the **normal issue
tracker** instead:

- Create a GitHub Issue at  
  `https://github.com/RafaelVVolkmer/libmemalloc/issues`

This helps keep the private security channel focused on real vulnerabilities.

---

## 6. Responsible Use 🔐

libmemalloc is intended to be used as part of larger systems that may have
their own threat models and security requirements. Even with security fixes in
place, you are responsible for:

- Compiling with appropriate hardening flags (e.g. `-fstack-protector`,
  `-D_FORTIFY_SOURCE=2`, etc., as supported by your toolchain).
- Running tests under sanitizers when possible.
- Keeping your dependencies, compiler, and runtime environment up-to-date.

If you have suggestions to improve the security posture of libmemalloc (e.g.
better hardening defaults, safer APIs, documentation clarifications), feel free
to open an issue or pull request.
