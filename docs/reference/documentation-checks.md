<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Documentation verification reference

Use the [documentation guide](../getting-started/documentation.md#validation) for commands and dependency setup.
`scripts/check/documentation.lua` confines task inventories to product SDD files.
Its contract suite covers ordinary documents, product specifications and forbidden task inventories.
Review rationale and evidence in issues and pull requests using the
[engineering review procedure](../procedures/decision-making.md).

<details>
<summary><strong>On this page</strong></summary>

- [CICD-005: Source and documentation checks](#cicd-005)
- [CICD-006: Spelling, prose, and references](#cicd-006)
- [Local acceptance](#local-acceptance)

</details>

---

<a id="cicd-005"></a>

## CICD-005: Source and documentation checks

**Class:** ANALYZABILITY. **Obligation:** project requirement.

The reusable lint workflow checks Actions, EditorConfig, C, Lua, Markdown,
Mermaid, and applicable configuration or scripting languages. Validate the npm
graph before using its documentation tools. Do not treat a missing required tool
as an empty source selection.

Markdown checks cover repository documentation, including SDDs, examples, and
workflow guides. Generated dependency directories and license texts are not
authored Markdown. Preserve stable control anchors when rebuilding indexes.
Do not replace broken evidence links with invented files or successful results.

**Evidence:** [lint workflow](../../.github/workflows/_lint.yml),
[tool validation](../../scripts/check/doc_tools.lua), and
[diagram validation](../../scripts/check/mermaid.lua).

---

<a id="cicd-006"></a>

## CICD-006: Spelling, prose, and references

**Class:** DOCUMENTATION. **Obligation:** project requirement.

Documentation is written in English. CSpell, codespell, typos, Vale, and Lychee
have separate purposes; passing one does not replace the others. Inspect prose
suggestions as well as blocking errors. Do not whitelist a misspelling simply
to make a gate green. Add reviewed technical terms to the shared dictionary and
regenerate its adapters.

Use descriptive reference titles. A reader must know the destination without
decoding a numeric bibliography label. Keep requirement and test IDs because
they identify contracts, not bibliographic entries.

Change detection selects when the link job runs. The [link checker](../../scripts/check/links.lua)
then checks the authored working-file inventory, including untracked additions. External links are checked on
default-branch pushes, manual runs, and releases. Offline success proves neither
remote availability nor the truth of a cited claim.
Timeouts fail the online check. Rate-limit and server-error responses are excluded from the cache
so a later attempt can retry them; they are not accepted as valid links.

The commit-message hook checks HTTP links with Lychee when the tool is installed.
It supplies the message through standard input so the temporary `.cache/` path does not exclude it.
The aggregate checker and reusable spelling workflow run an offline regression with real Lychee:
an existing local target must pass, a missing target must fail, and a message without HTTP links
must not invoke the link checker. Missing optional hook tools emit warnings; aggregate checks require
their declared tools.

**Evidence:** [spelling workflow](../../.github/workflows/_spelling.yml) and
[shared dictionary generator](../../tools/lint/spell/dictionary/generate.lua).

---

## Local acceptance

Run the commands in the [CI index](automation.md#local-checks), then Markdown,
spelling, prose, link, license, and Actions validators with repository configurations.
The shared working-file inventory includes new, untracked documentation and omits deleted sources.
When validating a commit in isolation, use a clean checkout with its required tooling and distinguish
that result from checks over pending changes in the working tree.

Report each validator's status and its scope. Do not report all tests passing
when a required validator was unavailable or when only a filtered subset ran.

<!-- EOF -->

