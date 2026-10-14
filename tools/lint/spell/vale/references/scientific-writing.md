<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# Scientific writing standard

This profile defines a venue-neutral baseline for technical and scientific
articles. A target journal or conference policy takes precedence if it
conflicts with this document.

## Article structure

Use the following sequence for a compatible study design:

1. Abstract: state the problem, method, principal numeric result, and scope of
    the conclusion.
2. Introduction: identify the specific knowledge gap and cite prior work.
3. Methods: name materials, data, software versions, parameters, sample sizes,
    exclusions, and analysis procedures.
4. Results: report observations with units, uncertainty, effect sizes, and the
    comparison baseline.
5. Discussion: interpret the results, limitations, and threats to validity
    without repeating the Results section.
6. Conclusion: answer the research question within the tested conditions.

Reviews, position papers, and proofs may use another section structure. Their
headings must expose the argument and evidence sequence.

## Agency and voice

Use a human subject for each action that involves judgment or choice. Write
`We selected the threshold`; avoid `The threshold was selected`. If `we` is
ambiguous, name participants, operators, reviewers, or authors.

Machines may execute operations. Write `The compiler emitted an error` for a
defined operation and observable output. Reserve belief, intent, discovery, and
judgment for people; exclude these traits from software, data, papers, and experiments.

## Claims and evidence

Each empirical claim must identify the population or workload, metric,
baseline, measured value, uncertainty, and source. Distinguish association
from causation. Reserve `prove` for a proof with stated premises.

For statistical significance, report the test, effect size, uncertainty, exact
value, sample size, and practical interpretation. A threshold provides
insufficient support for a conclusion.

## Numbers and units

Use International System of Units (SI) symbols and a space between each value
and unit. Use a non-breaking space to prevent separation during line wrapping.
Add a leading zero to decimal values
below one. Put one space on each side of mathematical and statistical
operators. Define each symbol at first use.

## Citations and reproducibility

Cite the primary source for a method, dataset, prior result, or attributed
claim. Keep citations next to the claim they support. Replace placeholders
before review.

Give enough information for another researcher to repeat the work: versioned
artifacts, inputs, parameters, random seeds, environment, exclusions, and
analysis code. Replace phrases such as `default settings` with recorded values.

## Manual quality score

Assign each dimension a score from 1 through 10 after Vale passes. Record one sentence
of evidence for each score.

| Dimension | Review question |
| --- | --- |
| Directness | Does each sentence state a fact or announce that a fact will follow? |
| Rhythm | Do sentence lengths and openings vary without a repeated template? |
| Trust | Does the prose respect reader knowledge and omit hand-holding? |
| Authenticity | Does the wording reflect the actual work, choices, and limits? |
| Density | Can the reviewer remove any phrase without losing evidence or meaning? |

A total below 35 out of 50 requires revision. The reviewer must supply the
score because a lexical rule cannot judge trust, authenticity, or evidentiary
density.

## Delivery check

Before publication, confirm that the text contains no unexplained adverb,
passive construction, false agency, vague declaration, formulaic contrast,
meta-joiner, rhetorical setup, em dash, or unsupported extreme. Compare three
consecutive sentences and paragraph endings for repeated rhythm. Rewrite any
line that reads like a slogan without evidence.

<!-- EOF -->

