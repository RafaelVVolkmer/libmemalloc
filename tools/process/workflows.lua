-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Reviewed commands shared by workflow dispatch and native Ansible.
--- Return explicit task records; source paths are never discovered at runtime.
-- @return table: reviewed commands shared by workflow dispatch and native
-- Ansible.
local function WORKFLOW_TASKS_loadModule()
   return {
      ["native-resources-test"] = {
         command = { "scripts/process/native/check.lua" },
         description = "Test native resource containment, live logs and supervisor death",
         dependencies = { "python3" },
         effects = "read",
         simulation = "plan",
         timeout_seconds = 300,
      },
      ["check-haskell"] = {
         resource_profile = "formal",
         command = { "scripts/verification/check-haskell.lua" },
         description = "Lint Haskell sources and run the verifier regression"
            .. " suite",
         dependencies = { "git", "systemctl", "systemd-run" },
         effects = "read",
         simulation = "plan",
         timeout_seconds = 3600,
      },
      ["check-lean"] = {
         resource_profile = "formal",
         command = { "scripts/verification/check.lua" },
         description = "Audit Lean proofs, contract baselines and trust "
            .. "controls",
         dependencies = {
            "git",
            "sha256sum",
            "flock",
            "systemctl",
            "systemd-run",
         },
         effects = "read",
         simulation = "plan",
         timeout_seconds = 5400,
      },
      ["formal-bootstrap"] = {
         resource_profile = "formal",
         command = { "scripts/verification/bootstrap-engine.lua" },
         description = "Prepare pinned compilers and formal verification "
            .. "dependencies",
         dependencies = {
            "git",
            "curl",
            "tar",
            "sha256sum",
            "systemctl",
            "systemd-run",
         },
         effects = "workspace",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["formal-resources-test"] = {
         command = { "tests/automation/process/resources_test.lua" },
         description = "Verify formal resource containment and recovery",
         resource_profile = "formal",
         dependencies = { "cc", "systemctl", "systemd-run" },
         effects = "read",
         simulation = "plan",
         timeout_seconds = 300,
      },
      ["formal-executor-test"] = {
         command = { "tests/automation/process/formal_executor_test.lua" },
         description = "Verify official formal supervision and kernel leases",
         resource_profile = "formal",
         dependencies = { "flock", "systemctl", "systemd-run" },
         effects = "read",
         simulation = "plan",
         timeout_seconds = 300,
      },
      ["check-workflows"] = {
         command = { "scripts/check/workflows.lua" },
         description = "Check documentation publication migration consistency",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 60,
      },
      ["github-cache-plane"] = {
         command = { "scripts/github/cache_plane.lua" },
         description = "Validate and configure repository cache services",
         dependencies = {},
         effects = "workspace",
         simulation = "plan",
         timeout_seconds = 60,
      },
      ["analysis-run"] = {
         command = { "scripts/analysis/run.lua" },
         description = "Execute independent campaigns even when an earlier "
            .. "campaign fails",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["build-plan"] = {
         command = { "scripts/build/plan.lua" },
         description = "Run the plan operation under its declared inputs and "
            .. "evidence contract",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["build-report"] = {
         command = { "scripts/build/report.lua" },
         description = "Aggregate against the planner, never against the "
            .. "subset that happened to return",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["build-run"] = {
         command = { "scripts/build/run.lua" },
         description = "Build each C configuration once, link its C++ "
            .. "consumers, and execute CTest",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-c"] = {
         command = { "scripts/check/c.lua" },
         description = "Run repository C formatting and static analysis "
            .. "locally or in CI. Override tool paths with "
            .. "LIBMEMALLOC_CLANG_FORMAT and LIBMEMALLOC_CLANG_TIDY",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-c-analysis"] = {
         command = { "scripts/check/c_analysis.lua" },
         description = "Independent engines and local structural rules, with "
            .. "explicit coverage",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-commits"] = {
         command = { "scripts/check/commits.lua" },
         description = "Validate the selected commit range against the "
            .. "repository message policy",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-doc-examples"] = {
         command = { "scripts/check/doc_examples.lua" },
         description = "Check references and the explicitly named complete C "
            .. "example files. Deliberately invalid failure fragments "
            .. "are never compiled or executed",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-doc-tools"] = {
         command = { "scripts/check/doc_tools.lua" },
         description = "Verify the npm graph using Node's native JSON reader "
            .. "before installation",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-documentation"] = {
         command = { "scripts/check/documentation.lua" },
         description = "Enforce the document policy and scope of task "
            .. "inventories",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-eof"] = {
         command = { "scripts/check/eof.lua" },
         description = "Require an EOF comment and surrounding blank lines in "
            .. "owned text formats",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-format"] = {
         command = { "scripts/check/format.lua" },
         description = "Check formatter output while preserving the "
            .. "repository EOF blank line. Formatters remove trailing "
            .. "empty lines. Check that one terminal exception "
            .. "separately; do not ignore any other formatter "
            .. "difference",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-install"] = {
         command = { "scripts/check/install.lua" },
         description = "Qualify a relocated installation with consumers "
            .. "outside the source tree",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-links"] = {
         command = { "scripts/check/links.lua" },
         description = "Check tracked Markdown while keeping Lychee's "
            .. "fixed-name cache out of sources",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-lua"] = {
         command = { "scripts/check/lua.lua" },
         description = "Run the repository Lua quality policy locally or in "
            .. "CI. Tool paths may be overridden through "
            .. "LIBMEMALLOC_* environment variables",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-mermaid"] = {
         command = { "scripts/check/mermaid.lua" },
         description = "Validate Mermaid with its official parser, without "
            .. "generated script files",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-msvc"] = {
         command = { "scripts/check/msvc.lua" },
         description = "Windows native analysis; use the selected SDK without "
            .. "replacing its models",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-openssf"] = {
         command = { "scripts/check/openssf.lua" },
         description = "Validate evidence relationships. Governance claims "
            .. "require external evidence",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-reproducible"] = {
         command = { "scripts/check/reproducible.lua" },
         description = "Verify the recorded byte comparisons against the "
            .. "current release payloads",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-spelling"] = {
         command = { "scripts/check/spelling.lua" },
         description = "Run one shared source spelling policy locally and in "
            .. "CI. Every scanner receives working sources instead of "
            .. "generated dependency trees",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-ci-gate"] = {
         command = { "scripts/check/ci_gate.lua" },
         description = "Require every selected hosted check to succeed",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 60,
      },
      ["test-build-junit-test"] = {
         command = { "tests/automation/build/junit_test.lua" },
         description = "Reject malformed XML and forged CTest outcomes",
         dependencies = { "cmake", "ctest", "git" },
         effects = "read",
         simulation = "plan",
         timeout_seconds = 60,
      },
      ["check-toolchain"] = {
         command = { "scripts/check/toolchain.lua" },
         description = "Verify tool manifests, native locks and Actions",
         dependencies = { "git", "jq" },
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["check-web"] = {
         command = { "scripts/check/web.lua" },
         description = "Validate authored web sources selected by the caller "
            .. "or the CI change map. Uses the hash-locked npm graph; "
            .. "never installs dependencies during a check",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["documentation-main"] = {
         command = { "scripts/documentation/main.lua" },
         description = "Run from the repository root; build and eval never "
            .. "download dependencies",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["github-specifications"] = {
         command = { "scripts/github/specifications.lua" },
         description = "Synchronize the label catalog or reconcile reserved "
            .. "labels on one issue. Runs against trusted "
            .. "default-branch code; requires gh authentication. "
            .. "Issue text and proposed source code never enter an "
            .. "executable command",
         dependencies = {},
         effects = "remote",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["qualification-batch"] = {
         command = { "scripts/qualification/batch.lua" },
         description = "Prepare once, execute isolated cases, retain every "
            .. "result and fail closed",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["qualification-dependencies"] = {
         command = { "scripts/qualification/dependencies.lua" },
         description = "Download each producer package once for all consumers "
            .. "assigned to this job",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["qualification-plan"] = {
         command = { "scripts/qualification/plan.lua" },
         description = "Expand a campaign into tasks, dependencies and "
            .. "workflow matrices",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["qualification-report"] = {
         command = { "scripts/qualification/report.lua" },
         description = "Aggregate worker evidence and compare independently "
            .. "reconstructed artifacts",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["release-build"] = {
         command = { "scripts/release/build.lua" },
         description = "Build and compare two isolated Linux mock candidates; "
            .. "never publish them",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["release-check-schemas"] = {
         command = { "scripts/release/check_schemas.lua" },
         description = "Validate complete SBOM schemas after checking their "
            .. "trusted digests",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["release-conan"] = {
         command = { "scripts/release/conan.lua" },
         description = "Publish the verified mock package through the "
            .. "selected Conan remote",
         dependencies = {},
         effects = "remote",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["release-package"] = {
         command = { "scripts/release/package.lua" },
         description = "Create the mock distribution archive from a verified "
            .. "release tree",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["release-sign"] = {
         command = { "scripts/release/sign.lua" },
         description = "Seal a new signed copy; leave the unsigned candidate "
            .. "immutable",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["release-verify"] = {
         command = { "scripts/release/verify.lua" },
         description = "Verify detached release signatures under the "
            .. "configured trust identities",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["reproducible-build"] = {
         command = { "scripts/reproducible/build.lua" },
         description = "Rebuild complete install trees without consulting a "
            .. "compiler cache",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["reproducible-compare"] = {
         command = { "scripts/reproducible/compare.lua" },
         description = "Compare raw packages first; retain deep diagnostics "
            .. "without accepting drift",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["reproducible-install"] = {
         command = { "scripts/reproducible/install.lua" },
         description = "Install explicit Ubuntu package versions on the "
            .. "disposable Actions runner",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["reproducible-normalizers"] = {
         command = { "scripts/reproducible/normalizers.lua" },
         description = "Qualify alternative normalizers on copies, never on "
            .. "the compared originals",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["reproducible-prepare"] = {
         command = { "scripts/reproducible/prepare.lua" },
         description = "Freeze only declared build inputs, including "
            .. "uncommitted review changes",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["reproducible-vary"] = {
         command = { "scripts/reproducible/vary.lua" },
         description = "Run an explicit environment campaign and preserve the "
            .. "tool's full evidence",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["security-plan"] = {
         command = { "scripts/security/plan.lua" },
         description = "Use the adapter catalog as the only authority for the "
            .. "assessment matrix",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["security-report"] = {
         command = { "scripts/security/report.lua" },
         description = "Reconcile every catalog entry even when installation "
            .. "or a service failed",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["security-run"] = {
         command = { "scripts/security/run.lua" },
         description = "Execute one OpenSSF integration and retain failures "
            .. "and blocked prerequisites. Dependencies install into "
            .. ".cache; remote assessments use read-only authority",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["toolchain-install-build"] = {
         command = { "scripts/toolchain/install/build.lua" },
         description = "Provision a group once; individual build cells never "
            .. "install dependencies",
         dependencies = {},
         effects = "workspace",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["toolchain-install-c-analysis"] = {
         command = { "scripts/toolchain/install/c_analysis.lua" },
         description = "Install selected analysis tools; policy versions live "
            .. "only in the TOML lock",
         dependencies = {},
         effects = "workspace",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["toolchain-install-c-scanners"] = {
         command = { "scripts/toolchain/install/c_scanners.lua" },
         description = "Install checksum-verified C analyzers into the "
            .. "repository cache",
         dependencies = {},
         effects = "workspace",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["toolchain-install-qualification"] = {
         command = { "scripts/toolchain/install/qualification.lua" },
         description = "Provision the native qualification adapter from its "
            .. "versioned host policy",
         dependencies = {},
         effects = "workspace",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["toolchain-install-quality"] = {
         command = { "scripts/toolchain/install/quality.lua" },
         description = "Install the same locked quality tools for local "
            .. "checks and Linux CI. Downloads remain hash verified; "
            .. "npm and Python use their reviewed lockfiles",
         dependencies = {},
         effects = "workspace",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["toolchain-sync"] = {
         command = { "scripts/toolchain/sync.lua" },
         description = "Generate tool manifests and Action pins from the lock",
         dependencies = { "git" },
         effects = "workspace",
         simulation = "plan",
         timeout_seconds = 60,
      },
      ["nix-setup"] = {
         command = { "scripts/toolchain/nix.lua" },
         description = "Prepare project tools when Nix is available",
         dependencies = { "git" },
         effects = "workspace",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["toolchain-python"] = {
         command = { "scripts/toolchain/python.lua" },
         description = "Synchronize Python tool groups from "
            .. "tools/python/pyproject.toml and tools/python/uv.lock. "
            .. "This explicit installer "
            .. "downloads a hash-verified uv when no override exists",
         dependencies = {},
         effects = "workspace",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["toolchain-resolve"] = {
         command = { "scripts/toolchain/resolve.lua" },
         description = "Publish locked tool identities for workflow consumers",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["workspace-bootstrap"] = {
         command = { "scripts/workspace/bootstrap.lua" },
         description = "Install the pinned automation runtime into "
            .. "tool-specific cache directories. Explicit network "
            .. "operation for the Linux x86_64 / Python 3.12 host "
            .. "profile. Source archives and every Python wheel must "
            .. "match reviewed SHA-256 hashes",
         dependencies = {},
         effects = "workspace",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["workspace-cache"] = {
         command = { "scripts/workspace/cache.lua" },
         description = "Run a local command with repository-owned disposable "
            .. "state. Usage: lua scripts/workspace/cache.lua COMMAND "
            .. "[ARGUMENT ...]. The child inherits credentials; this "
            .. "wrapper never prints its environment",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["workspace-changes"] = {
         command = { "scripts/workspace/changes.lua" },
         description = "Classify changed repository paths for selective CI "
            .. "execution. Full validation can be forced for trusted "
            .. "integration and release events",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["workspace-doctor"] = {
         command = { "scripts/workspace/doctor.lua" },
         description = "Diagnose automation prerequisites without changing "
            .. "the checkout. Reports managed and selected tools; "
            .. "domain campaigns keep their own checks",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-analysis-analysis-test"] = {
         command = { "tests/automation/analysis/analysis_test.lua" },
         description = "Adversarial tests for compiler-dependency parsing and "
            .. "module boundaries",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-build-evidence-test"] = {
         command = { "tests/automation/build/evidence_test.lua" },
         description = "Reject tampered or displaced test evidence before a "
            .. "build cell can pass",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-build-io-test"] = {
         command = { "tests/automation/build/io_test.lua" },
         description = "Exercise query argument boundaries and temporary-file "
            .. "cleanup on failures. The jq port records argv; "
            .. "directory creation and removal use the real host",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-build-matrix-test"] = {
         command = { "tests/automation/build/matrix_test.lua" },
         description = "Validate build profile selection and planned campaign "
            .. "coverage",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-check-ci-policy-test"] = {
         command = { "tests/automation/check/ci_policy_test.lua" },
         description = "Execute action policy scripts with adversarial inputs "
            .. "and no cloud access",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-documentation-driver-test"] = {
         command = { "tests/automation/documentation/driver_test.lua" },
         description = "Exercise real Doxygen evaluation, input separation "
            .. "and publication assets",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-documentation-filter-test"] = {
         command = { "tests/automation/documentation/filter_test.lua" },
         description = "Preserve authored code and links through the Doxygen "
            .. "Markdown filter",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-documentation-html-test"] = {
         command = { "tests/automation/documentation/html_test.lua" },
         description = "Verify generated graph links, page markers and script "
            .. "boundaries",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-documentation-policy-test"] = {
         command = { "tests/automation/documentation/policy_test.lua" },
         description = "Positive and negative contracts for documentation "
            .. "task inventories",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-github-specifications-test"] = {
         command = { "tests/automation/github/specifications_test.lua" },
         description = "Exercise maintainer label authority and API argument "
            .. "boundaries offline. Tests use pure event data and "
            .. "injected API ports; no GitHub mutation occurs",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-lib-git-test"] = {
         command = { "tests/automation/lib/git_test.lua" },
         description = "Check working-tree discovery without staging files or "
            .. "reviving deletions",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-lib-platform-test"] = {
         command = { "tests/automation/lib/platform_test.lua" },
         description = "Run on each native host: cmd quoting failures "
            .. "previously stopped MSVC",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-process-playbook-test"] = {
         command = { "tests/automation/process/playbook_test.lua" },
         description = "Verify task descriptions, argument boundaries and "
            .. "dispatch outcomes. Inject the supervisor so no task "
            .. "writes files or calls external services",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-qualification-batch-test"] = {
         command = { "tests/automation/qualification/batch_test.lua" },
         description = "Exercise continuation and failure propagation through "
            .. "the real batch driver",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-qualification-policy-test"] = {
         command = { "tests/automation/qualification/policy_test.lua" },
         description = "Validate qualification graphs, dependencies and "
            .. "evidence acceptance",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-qualification-profiles-test"] = {
         command = { "tests/automation/qualification/profiles_test.lua" },
         description = "Check weighted reduction and rejection through the "
            .. "real merge entrypoint",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-release-release-test"] = {
         command = { "tests/automation/release/release_test.lua" },
         description = "Exercise canonical release paths, serialization and "
            .. "tamper rejection",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-release-signature-test"] = {
         command = { "tests/automation/release/signature_test.lua" },
         description = "Exercise real Cosign cryptography without OIDC, "
            .. "uploads, or production keys",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-reproducible-comparison-test"] = {
         command = { "tests/automation/reproducible/comparison_test.lua" },
         description = "Reject missing packages, unexpected files and "
            .. "metadata-only byte drift",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-reproducible-tools-test"] = {
         command = { "tests/automation/reproducible/tools_test.lua" },
         description = "Prove that the comparator rejects drift and the "
            .. "normalizer preserves data",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-security-openssf-test"] = {
         command = { "tests/automation/security/openssf_test.lua" },
         description = "Reject missing, foreign and unqualified integration "
            .. "reports",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-toolchain-host-test"] = {
         command = { "tests/automation/toolchain/host_test.lua" },
         description = "Validate native archive selection and reject "
            .. "unsupported hosts",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 300,
      },
      ["test-toolchain-lock-test"] = {
         command = { "tests/automation/toolchain/lock_test.lua" },
         description = "Verify version parsing and reject incomplete or "
            .. "conflicting tool locks",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-toolchain-provision-test"] = {
         command = { "tests/automation/toolchain/provision_test.lua" },
         description = "Exercise installation command construction without "
            .. "downloading or installing",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-toolchain-python-test"] = {
         command = { "tests/automation/toolchain/python_test.lua" },
         description = "Verify native Python source builds preserve "
            .. "unrelated package locks",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 300,
      },
      ["test-workspace-cache-test"] = {
         command = { "tests/automation/workspace/cache_test.lua" },
         description = "Check owned temporary paths, cleanup restrictions, "
            .. "and OpenSSF catalog scope",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-workspace-changes-test"] = {
         command = { "tests/automation/workspace/changes_test.lua" },
         description = "Check selective CI categories against controlled Git "
            .. "changes",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-workspace-commit-links-test"] = {
         command = { "tests/automation/workspace/commit_links_test.lua" },
         description = "Check valid and broken commit links with real Lychee",
         dependencies = { "git", "lychee" },
         effects = "read",
         simulation = "plan",
         timeout_seconds = 120,
      },
      ["test-workspace-commit-range-test"] = {
         command = { "tests/automation/workspace/commit_range_test.lua" },
         description = "Exercise the hosted commit selector with a local "
            .. "remote and rewritten refs",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-workspace-commits-test"] = {
         command = { "tests/automation/workspace/commits_test.lua" },
         description = "Check accepted commit messages and policy rejection "
            .. "diagnostics",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-workspace-hooks-test"] = {
         command = { "tests/automation/workspace/hooks_test.lua" },
         description = "Check hook reference policy and fail-closed process "
            .. "decisions",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
      ["test-workspace-lease-test"] = {
         command = { "tests/automation/workspace/lease_test.lua" },
         description = "Exercise POSIX lease contention and release "
            .. "after process death",
         dependencies = { "python3" },
         effects = "read",
         simulation = "plan",
         timeout_seconds = 300,
      },
      ["test-workspace-lock-test"] = {
         command = { "tests/automation/workspace/lock_test.lua" },
         description = "Verify workspace locks reject conflicting "
            .. "maintenance and recover",
         dependencies = { "git", "python3" },
         effects = "read",
         simulation = "plan",
         timeout_seconds = 300,
      },
      ["test-workspace-settings-test"] = {
         command = { "tests/automation/workspace/settings_test.lua" },
         description = "Check source attributes, disposable paths and Git "
            .. "setup idempotence",
         dependencies = {},
         effects = "read",
         simulation = "plan",
         timeout_seconds = 7200,
      },
   }
end

return WORKFLOW_TASKS_loadModule()

-- EOF

