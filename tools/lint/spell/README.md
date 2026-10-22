<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Prose quality configuration

This directory is the source of truth for spelling, link, and prose checks.
Run each command from the repository root.

```sh
lua tools/lint/spell/dictionary/generate.lua --check
npx --yes cspell lint --config tools/lint/spell/cspell/cspell.jsonc .
codespell --config tools/lint/spell/codespell/.codespellrc .
typos --config tools/lint/spell/typos/typos.toml .
lychee --config tools/lint/spell/lychee/lychee.toml .
vale --config tools/lint/spell/vale/.vale.ini .
```

## Canonical vocabulary

The reviewed source vocabulary lives under `dictionary`, with one term per
line and categories for acronyms, C APIs, C terminology, project terminology,
and proper names. Add a recurring domain term to the narrowest category. Fix a
real spelling error in its source document. Reserve the vocabulary for valid
domain terms.

The generator combines the category files into `dictionary/libmemalloc-words.txt`.
CSpell and codespell consume this central word list. The other tools
require native adapters, generated with:

```sh
lua tools/lint/spell/dictionary/generate.lua
```

The generator creates the central word list and Vale vocabulary, and updates
the generated sections of the typos word table and Vale acronym rules. It
rejects duplicate, unsorted, or malformed source entries. CI runs `--check` so
a canonical vocabulary change cannot leave stale adapters behind.

Use the generator to update generated content. Keep spelling and acronym checks
active across each document. A document-specific term may use a scoped inline
directive, but recurring technical language belongs in the canonical vocabulary.

Generated npm locks contain upstream package identities and integrity hashes.
Codespell excludes these locks and installed dependency directories from prose
checks. The dependency graph validator and security audit check the locks.

## External link checks

External checks reject HTTP errors, including missing pages and exhausted rate
limits. The Lychee configuration remaps four article identifiers to their
registration records, selected Ansible pages to their official source files,
and one blocked standards preview to the same sample already cited elsewhere.
Three unavailable university references use the corresponding published
article, registration record or another academic copy. The Cppcheck manual
uses its official source file when the rendered site blocks automated clients.
These checks establish that the reference or source exists; they do not establish
availability of the publisher's rendered page from a CI runner.

Two exact community discussion URLs require browser review because hosted CI
receives HTTP 403. Their titles and contents were checked on 2026-10-21. They
appear as excluded in the automated report. Review these exceptions when editing
the references; do not extend them to entire domains or accept HTTP errors as
successful checks. Other existing exclusions remain listed in the configuration.
Access-denied, rate-limit and server-error responses are not cached.

Four exact standards pages also require manual review: two ECSS records
redirect automated requests to an unavailable ESA notice, and two NEN records
return HTTP 503. The cited editions were cross-checked on 2026-10-21 against
publisher search records and the corresponding national standards catalogues.
The configuration retains their original URLs and reports them as excluded;
automated availability of those four pages remains unverified. Review these
exceptions when the publisher service recovers or the references change.

External checks run in pull requests and merge groups as well as on the default
branch. HTTP errors, certificate failures and timeouts outside the documented
exceptions still fail the check. A passing run records availability at that
time; it does not guarantee future availability of third-party services.

## Vale policy

The broad `Libmemalloc` style contains spelling, anti-slop, and scientific rules. Its
base rules cover terminology, evidence, units, acronyms, and sentence mechanics.
Its anti-slop rules reject predictable filler and formulaic structures. Its
scientific rules cover claims, statistics, reproducibility, and article
conventions.

Files under `docs/articles`, `docs/papers`, and `docs/research` enable the
scientific mode. A file with a `.paper.md` suffix receives the same policy. Scientific
articles name authors or participants and omit second-person address.

The rules use three severity levels:

- `error` identifies objective defects, such as misspellings or missing spaces
  between values and units.
- `warning` identifies claims or constructions that require revision or
  supporting evidence.
- `suggestion` identifies sentences that benefit from human review but may be
  valid in context.

The style detects observable prose patterns and makes no inference about
whether a human or a model wrote the text. Its anti-slop rules target stock phrases,
promotional claims, vague references, unsupported attribution, and inflated
wording. The remaining rules improve technical precision through acronym
definitions, consistent units, concise sentences, and explicit actors.

The C language style guide and pitfall catalog are normative references. They use
the focused `LibmemallocSpelling` style, which keeps
spelling and acronym validation active across the complete documents without
applying narrative-prose heuristics to rule tables and compact requirements.

Use Vale's inline configuration comments for a justified, isolated
exception. Limit the suppression to one rule and the smallest relevant
passage.

The phrase lists and structural guidance live under `vale/references`. The
article template, delivery checklist, and manual 50-point rubric live in
`vale/references/scientific-writing.md`.

<!-- EOF -->

