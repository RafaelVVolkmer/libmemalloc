<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Pull Request

## Summary

Describe this pull request in 1 to 3 sentences.

Explain what problem it solves and why this change is needed.

## Change Type

Select all that apply.

- [ ] feat: new feature
- [ ] fix: bug fix
- [ ] chore: repository, tooling, build, or CI maintenance
- [ ] docs: documentation only
- [ ] refactor: code change without intended behavior change
- [ ] perf: performance improvement
- [ ] test: tests only
- [ ] security: security hardening or vulnerability fix
- [ ] release: release, versioning, packaging, or changelog update

## Related Issues

Use closing keywords when this pull request should close an issue after merge.

- Closes #
- Related to #

## Motivation

Explain the reason for this change.

- What limitation, defect, risk, or maintenance problem exists today?
- Why should this change be made now?
- What alternatives were considered, if any?

## Implementation Details

Describe what changed.

- Main files or components changed:
- Important design decisions:
- Trade-offs:
- Behavior before this change:
- Behavior after this change:

For allocator, GC, low-level memory, or portability changes, describe the
relevant allocation path, free path, ownership rule, metadata change, or
platform assumption.

## API and ABI Compatibility

Does this change affect public API or ABI?

- [ ] No public API change
- [ ] No ABI change
- [ ] API addition only
- [ ] API behavior changed
- [ ] ABI changed
- [ ] Breaking change

If there is any API or ABI impact, describe it below.

- Impacted functions, types, macros, or headers:
- Migration steps:
- Compatibility notes:
- Deprecation notes:

## Build and Toolchain Environment

Describe where this was developed, built, and tested.

- libmemalloc version, tag, or commit:
- Host OS and version:
- Target OS and version:
- Target architecture:
- Target CPU, SoC, board, or emulator:
- Compiler and version:
- C standard:
- Build system:
- Build type:

Build method:

- [ ] Project script
- [ ] CMake
- [ ] Make
- [ ] Docker
- [ ] Manual command
- [ ] Other

Commands used:

```sh
# paste exact build commands here
```

## Testing Evidence

Describe how this change was tested.

- [ ] Build completed successfully
- [ ] Unit tests passed
- [ ] Integration tests passed
- [ ] Manual tests completed
- [ ] Sanitizer run completed
- [ ] Fuzzing run completed
- [ ] Static analysis completed
- [ ] Not tested; reason documented below

Commands used:

```sh
# paste exact test commands here
```

Results summary:

```text
# paste relevant output, summary, or links to CI logs here
```

## Security and Memory-Safety Impact

Does this pull request touch security-sensitive or memory-sensitive code?

- [ ] No
- [ ] Yes, allocator internals
- [ ] Yes, free/realloc/calloc path
- [ ] Yes, pointer arithmetic
- [ ] Yes, bounds checks
- [ ] Yes, metadata layout
- [ ] Yes, logging or diagnostics that may expose data
- [ ] Yes, GC or tracing logic
- [ ] Yes, build, packaging, CI, or supply-chain security

If yes, describe:

- Risks mitigated:
- Risks introduced:
- Validation performed:
- Sanitizers used:
- Fuzzing performed:
- Static analysis performed:
- Manual review notes:

Do not include exploit details, secrets, private keys, production memory
dumps, customer data, or undisclosed vulnerability details in this pull
request. Use the private security reporting process described in
`SECURITY.md` for suspected vulnerabilities.

## Performance Impact

Does this change affect performance-sensitive paths?

- [ ] No significant performance impact expected
- [ ] Allocation hot path affected
- [ ] Free/realloc path affected
- [ ] Metadata or lookup path affected
- [ ] GC or tracing path affected
- [ ] Logging or diagnostics path affected
- [ ] Benchmark results included below

Benchmark summary, if applicable:

```text
# before:
# after:
# environment:
```

## Documentation Impact

Select all that apply.

- [ ] No documentation changes needed
- [ ] README updated
- [ ] Public API documentation updated
- [ ] Doxygen comments updated
- [ ] Architecture documentation updated
- [ ] Security documentation updated
- [ ] Build, install, or testing documentation updated
- [ ] Changelog updated

## Release and Packaging Impact

Select all that apply.

- [ ] No release impact
- [ ] Changelog entry required
- [ ] Version bump required
- [ ] Packaging metadata changed
- [ ] License or SPDX metadata changed
- [ ] SBOM or provenance metadata changed
- [ ] Release notes should mention this change

## Risk and Rollback

Risk level:

- [ ] Low
- [ ] Medium
- [ ] High

Rollback plan:

- [ ] Revert this pull request
- [ ] Disable through configuration
- [ ] Not applicable

Describe any special rollback or migration considerations:

```text
# notes
```

## Reviewer Notes

Mention areas that need careful review.

- Code paths needing extra attention:
- Assumptions to verify:
- Questions for reviewers:

## Contributor Checklist

- [ ] My branch name follows the project branch naming style.
- [ ] My commits follow the project commit message format.
- [ ] My commits include a valid Signed-off-by trailer.
- [ ] I have not included secrets, credentials, tokens, private keys,
      or private data.
- [ ] I have not included undisclosed vulnerability details in this public PR.
- [ ] I have updated tests or explained why no tests were needed.
- [ ] I have updated documentation or explained why no documentation was needed.
- [ ] I have considered API, ABI, build, runtime, security, and maintenance impact.
- [ ] I have checked formatting and linting where applicable.

## DCO Sign-off

By contributing, you certify that you have the right to submit this work
under the project's license and that you agree to the Developer Certificate
of Origin process used by this repository.

```text
Signed-off-by: <Your Name> <your.email@example.com>
```

<!-- EOF -->
