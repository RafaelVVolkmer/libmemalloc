<!--
SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
-->

# WebMCP capability and security contract

The Doxygen site exposes public documentation through eight read-only tools. It has no authenticated
application service, allocator execution, repository write access or release authority. The
[adapter](../../doxygen/web/scripts/webmcp.ts) implements this scope; its contract version is `1.0.0`.

<details>
<summary><strong>On this page</strong></summary>

- [Discovery and compatibility](#discovery-and-compatibility).
- [Inputs, effects and limits](#inputs-effects-and-limits).
- [Content and trust boundaries](#content-and-trust-boundaries).
- [Authenticated application integration](#authenticated-application-integration).
- [Verification evidence](#verification-evidence).

</details>

---

## Discovery and compatibility

Call `libmemalloc_capabilities` with `{}`. It returns the application name, contract version, JSON Schema
Draft 7 dialect, public audience, limits and successfully registered tools. Each tool includes its version,
description, input and output schemas, effects, confirmation policy and read-only/untrusted-content hints.
Discovery performs no network request. Responses are detached copies; editing one does not alter later discovery.

The [WebMCP draft](https://webmachinelearning.github.io/webmcp/) was reviewed on 2026-09-23.
Its registration dictionary exposes an input schema. Output schemas are application metadata in this
manifest, rather than an invented browser registration field. The
[MCP tool contract](https://modelcontextprotocol.io/specification/2026-07-28/server/tools)
has its own output schema support. Its revision date is not a WebMCP protocol version.

Incompatible changes require a new major capability version and a distinct registered name, such as
`libmemalloc_read_page_v2`. Keep the old name while it remains supported and record its retirement in this
reference. Additive optional fields can use a minor version. Changes to meaning require contract review
even when existing JSON remains structurally valid. Registration names use letters, digits, underscores,
hyphens and periods; versions belong in metadata, without an `@` suffix.

---

## Inputs, effects and limits

Every tool rejects undeclared arguments. Numeric pagination requires safe integers within the declared
bounds. Search accepts bounded literal text, without regular expressions or executable expressions.
Accessors, inherited parameter values and symbol properties are rejected before reading their values.
The browser may apply its own schema validation; execution repeats the relevant argument checks.

| Boundary | Implemented limit or behavior |
| --- | --- |
| Concurrent calls | At most four pending calls per adapter instance; callers retry after completion. |
| Serialized response | At most 524,288 JavaScript string characters; larger results fail. |
| Text chunks | At most 20,000 characters per call, with continuation offsets. |
| Outline | First 1,000 eligible headings, with names limited to 240 characters. |
| Semantic tree | At most 10,000 scanned elements and 200 returned nodes; reports scan truncation. |
| Catalog transfer | At most 2,097,152 decoded response-body bytes, counted while streaming. |
| Catalog entries | At most 10,000 entries; malformed or out-of-publication entries are omitted. |
| Catalog duration | Fetch and body consumption share a five-second abort timer and caller cancellation. |
| Catalog request | Fixed publication URL, same origin, no credentials or referrer, redirects rejected. |
| Catalog response | Successful HTTP status, exact response URL and JSON content type required. |
| Retention | Successful catalog cached in page memory; arguments and results are not logged. |

Only `libmemalloc_search_documentation` fetches data, from `documentation-index.json` next to the adapter.
Callers cannot provide a URL, path, origin, credential, authorization context or executable command.
A failed or cancelled response does not populate the cache. JSON is parsed as data without HTML insertion.

These public reads do not request human confirmation. The five-second timer applies to asynchronous network
work; it cannot preempt synchronous JavaScript or guarantee wall-clock completion in a suspended browser tab.
The local concurrency guard is a resource limit, not a server rate limiter.

---

## Content and trust boundaries

Prose, examples and contract text omit form fields, editable regions and descendants marked
`data-webmcp-private`, along with hidden/inert attributes and generated controls. Semantic-tree names also
exclude private label sources. The tree still reports public control labels and states, without typed values.
Citations omit URL credentials and query parameters; current-page fragments are cleared and authored link
fragments must have an ordinary anchor shape. Never place secrets in public document paths, titles or anchors.

The private marker prevents accidental inclusion by this adapter. It provides no confidentiality: anyone
receiving the page can inspect or modify its DOM and JavaScript. Hidden CSS, minification and omitted source
maps also cannot protect data already delivered to a browser. Publish only public material in this site.

Tool results and descriptions are untrusted data. Read-only annotations do not prevent prompt injection,
prove document accuracy or authorize another tool call. Consumers must keep returned instructions separate
from their own operating policy. The DOM semantic tree remains an approximation, not the browser accessibility
tree or evidence of accessibility conformance.

No cross-origin tool exposure is requested. Secure-context feature detection and browser permissions policy
remain applicable. Hosting headers are deployment responsibilities; these tests do not establish the deployed
Content Security Policy or Permissions Policy.

---

## Authenticated application integration

An application such as RLDoc needs a server boundary before any protected capability is introduced. This
repository does not implement that backend or claim that browser checks provide authentication.

| Contract | Authority and responsibility |
| --- | --- |
| Agent capabilities | Versioned semantic actions, schemas, effects and permitted scope discovered for the current identity. |
| Application API | Server endpoints and services enforce authorization for every referenced object and project. |
| Data schemas | Validate requests and responses at service boundaries, including path and identifier constraints. |
| Workflow | Explicit steps, success criteria and recovery; use Arazzo when workflows operate over suitable API descriptions. |

The server must derive identity, tenant and project permissions from verified authentication context, enforce
least privilege, reject identifiers outside that scope and recheck authorization on every execution. Discovery
is not authorization: permissions can change after discovery. Neither an agent argument nor a browser flag may
override the authenticated context. Filesystem paths must remain within the authorized workspace.

Keep secrets, privileged integrations, policy decisions and protected workflow implementation on the server.
Use server-side execution limits and audit records for protected actions. Record identities, decisions and
outcomes while minimizing sensitive payloads. Select confirmation requirements from actual effects: ordinary
public reads need none; destructive and privileged actions require explicit confirmation bound to the operation.
Confirmation complements authorization and must not replace it.

OpenAPI describes HTTP interfaces; [Arazzo](https://spec.openapis.org/arazzo/latest.html) describes API workflows.
Neither is required to wrap this static documentation reader. Any future server integration must select and
record its own protocol versions, authentication mechanism, policy tests and deployment controls.

---

## Verification evidence

The [WebMCP tests](../../tests/automation/documentation/webmcp_test.cjs) exercise the emitted JavaScript with
mocked browser registration and a DOM fixture. They compile the published input/output schemas with the
validator in the locked web dependency graph and validate successful results, including missing and ambiguous
symbols. Tests cover redirects, response origin, content type, oversized streams, excessive entries, retries,
timeouts, cancellation, concurrency recovery, private content and URL filtering.

Run TypeScript compilation before the tests. The documentation build compiles and copies the adapter; set
`LIBMEMALLOC_WEB_ASSET` to its generated `webmcp.js` to test that published artifact. These checks establish
adapter behavior in fixtures. They do not replace testing a supported browser's native WebMCP implementation.

<!-- EOF -->

