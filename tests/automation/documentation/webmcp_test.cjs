/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-only
 */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(
  process.env.LIBMEMALLOC_WEB_ASSET || '.cache/docs/web/webmcp.js',
  'utf8',
);

async function environment({
  supported = true,
  secure = true,
  fail = false,
  pageURL = 'https://docs.example/libmemalloc/guide.html',
  scriptURL = 'https://docs.example/libmemalloc/webmcp.js',
  response,
  timeout,
} = {}) {
  const tools = new Map();
  const requests = [];
  const warnings = [];
  const main = {
    querySelector: () => ({
      closest: () => null,
      cloneNode: () => ({ textContent: 'Example page', querySelectorAll: () => [] }),
    }),
    cloneNode: () => ({
      textContent: 'first line\nsecond line\nthird line',
      querySelectorAll: () => [],
    }),
  };
  const document = {
    readyState: 'complete',
    currentScript: { src: scriptURL },
    getElementById: () => main,
    createElement: () => ({
      set innerHTML(value) {
        this.value = value;
      },
    }),
  };
  if (supported)
    document.modelContext = {
      async registerTool(tool) {
        if (fail) throw new Error('Permissions policy denied');
        tools.set(tool.name, tool);
      },
    };
  vm.runInNewContext(source, {
    document,
    navigator: {},
    window: { isSecureContext: secure },
    location: { href: pageURL },
    AbortController,
    TextDecoder,
    setTimeout: timeout || setTimeout,
    clearTimeout,
    URL,
    console: { warn: (...args) => warnings.push(args) },
    fetch: async (url, options) => {
      requests.push({ url: String(url), options });
      if (response) return response(url, options);

      return catalogResponse([
        { title: 'Allocator guide', url: 'guide.html' },
        { title: 'Allocator API', url: 'api.html' },
        { title: 'Allocator malicious URL', url: 'https://other.example/page.html' },
        { title: 'Allocator outside publication', url: '../other.html' },
      ]);
    },
  });
  await new Promise((resolve) => setImmediate(resolve));
  return { tools, requests, warnings };
}

// Use real streaming Response objects to exercise byte counting independently of headers.
function catalogResponse(entries, options = {}) {
  const response = new Response(options.body ?? JSON.stringify(entries), {
    headers: { 'content-type': 'application/json', ...options.headers },
    status: options.status || 200,
  });

  Object.defineProperty(response, 'url', {
    value: options.url || 'https://docs.example/libmemalloc/documentation-index.json',
  });
  Object.defineProperty(response, 'redirected', { value: options.redirected || false });

  return response;
}

// Compile published schemas using the validator in the locked web dependency graph.
async function verifyContracts(tools) {
  const Ajv = require(`${process.cwd()}/.cache/tools/web/node_modules/ajv`);
  const validator = new Ajv({ strict: true, allErrors: true });
  const manifest = await tools.get('libmemalloc_capabilities').execute({});

  assert.equal(manifest.contractVersion, '1.0.0');
  assert.equal(manifest.tools.length, tools.size);

  for (const capability of manifest.tools) {
    const validate = validator.compile(capability.outputSchema);
    const tool = tools.get(capability.name);
    const execute = tool.execute;

    validator.compile(capability.inputSchema);
    tool.execute = async (...args) => {
      const result = await execute(...args);

      assert.ok(validate(result), `${tool.name}: ${JSON.stringify(validate.errors)}`);

      return result;
    };
  }

  // Discovery is detached: a caller cannot poison later metadata or limits.
  manifest.tools[0].inputSchema.additionalProperties = true;
  manifest.limits.catalogBytes = 0;
  const fresh = await tools.get('libmemalloc_capabilities').execute({});

  assert.equal(fresh.tools[0].inputSchema.additionalProperties, false);
  assert.ok(fresh.limits.catalogBytes > 0);
}

// Reject hostile responses and recover concurrency slots after cancellation or failure.
async function networkSecurity() {
  assert.equal((await environment({ scriptURL: 'https://other.example/webmcp.js' })).tools.size, 0);

  const rejected = [
    () => catalogResponse([], { redirected: true }),
    () => catalogResponse([], { url: 'https://other.example/index.json' }),
    () => catalogResponse([], { headers: { 'content-type': 'text/html' } }),
    () => catalogResponse([], { status: 503 }),
    () => catalogResponse({ unexpected: 'object' }),
    () => catalogResponse([], { body: '{invalid JSON' }),
    () => catalogResponse([], { body: new Uint8Array([0xff]) }),
    () => catalogResponse(Array(10001).fill({ title: 'page', url: 'page.html' })),
    () => catalogResponse('x'.repeat(2 * 1024 * 1024), { headers: { 'content-length': '1' } }),
  ];

  for (const response of rejected) {
    let attempts = 0;
    const state = await environment({
      response: () => {
        attempts += 1;
        return attempts === 1
          ? response()
          : catalogResponse([{ title: 'Retry', url: 'retry.html' }]);
      },
    });
    const search = state.tools.get('libmemalloc_search_documentation').execute;

    await assert.rejects(search({ query: 'retry' }));
    assert.equal((await search({ query: 'retry' })).total, 1);
  }

  // An abort-aware hanging fetch represents both a server stall and caller cancellation.
  const hanging = (_url, { signal }) =>
    new Promise((_resolve, reject) => {
      const abort = () => reject(new Error('aborted'));

      signal.addEventListener('abort', abort, { once: true });
      if (signal.aborted) abort();
    });
  const timed = await environment({
    response: hanging,
    timeout: (callback) => setTimeout(callback, 5),
  });

  await assert.rejects(
    timed.tools.get('libmemalloc_search_documentation').execute({ query: 'timeout' }),
    /aborted/,
  );

  // Fetch may finish while the body stalls; its stream must receive the same abort signal.
  let bodyAborted = false;
  const stalledBody = await environment({
    timeout: (callback) => setTimeout(callback, 5),
    response: (_url, { signal }) =>
      catalogResponse([], {
        body: new ReadableStream({
          start(controller) {
            controller.enqueue(new TextEncoder().encode('['));
            signal.addEventListener(
              'abort',
              () => {
                bodyAborted = true;
                controller.error(new Error('body aborted'));
              },
              { once: true },
            );
          },
        }),
      }),
  });

  await assert.rejects(
    stalledBody.tools.get('libmemalloc_search_documentation').execute({ query: 'stall' }),
    /body aborted/,
  );
  assert.equal(bodyAborted, true);

  const state = await environment({ response: hanging });
  const controller = new AbortController();
  const search = state.tools.get('libmemalloc_search_documentation').execute;
  const pending = Array.from({ length: 4 }, () =>
    search({ query: 'pending' }, { signal: controller.signal }),
  );
  const settled = Promise.allSettled(pending);

  await assert.rejects(search({ query: 'overflow' }), /concurrent/);
  controller.abort();
  assert.ok((await settled).every((result) => result.status === 'rejected'));
  await state.tools.get('libmemalloc_capabilities').execute({});

  const read = state.tools.get('libmemalloc_read_page').execute;
  const accessor = Object.defineProperty({}, 'offset', {
    get() {
      throw new Error('getter executed');
    },
  });

  await assert.rejects(read(accessor), /Unexpected tool arguments/);
  await assert.rejects(read(Object.create({ offset: 1 })), /Unexpected tool arguments/);
  await assert.rejects(read({ [Symbol('hidden')]: true }), /Unexpected tool arguments/);
}

// Exercise generated-page semantics with the same DOM implementation used by documentation checks.
async function documentationTools() {
  const { JSDOM } = require(`${process.cwd()}/.cache/tools/md/node_modules/jsdom`);
  const dom = new JSDOM(
    `<!doctype html><html><head><style>
    .invisible { display: none; }
  </style></head><body>
    <nav aria-label="Documentation"><a href="guide.html">Guide</a></nav>
    <main id="doc-content"><div class="contents">
      <h1>Allocator reference</h1><h2 id="ownership">Ownership</h2>
      <span id="toggle-name" hidden>Show contracts</span>
      <button id="toggle" aria-labelledby="toggle-name" aria-label="Wrong name"
        aria-expanded="false" aria-controls="contracts">Show</button>
      <a href="javascript:alert(1)">Unsafe address</a>
      <label for="search">Find symbol</label><input id="search" type="search" value="typed-secret">
      <input type="password" aria-label="Password" value="password-secret">
      <button disabled>Unavailable</button>
      <input type="checkbox" aria-label="Include internal" checked>
      <div role="heading" aria-level="3" id="contract-heading">Contract requirements</div>
      <div hidden><button>Hidden attribute</button></div>
      <div aria-hidden="true"><button>Hidden ARIA</button></div>
      <div class="invisible"><button>Hidden CSS</button></div>
      <div inert><button>Inert subtree</button></div>
      <details><summary>Closed details</summary><a href="hidden.html">Closed child</a></details>
      <div class="lma-code" data-language="c"><pre class="fragment" id="example">int count = 1;
  count += 2;</pre></div>
      <h2 class="memtitle"><a href="#allocate">◆</a>FIXTURE_allocate()</h2>
      <div class="memitem"><div class="memproto"><table><tr>
        <td class="memname">void * FIXTURE_allocate</td><td>(size_t count)</td>
      </tr></table></div><div class="memdoc">
        <p>Caller owns the returned memory.</p>
        <dl class="section pre"><dt>Precondition</dt><dd>Count must be positive.</dd></dl>
        <dl class="section return"><dt>Returns</dt><dd>NULL on failure.</dd></dl>
        <dl class="section user"><dt>Thread safety</dt><dd>Requires external locking.</dd></dl>
        <div class="fragment"><div class="line"><span class="lineno">1</span>int value;</div>
          <div class="line"><span class="lineno">2</span>return value;</div>
          <button>Copy noise</button></div>
        <div class="dyncontent">Diagram noise</div>
      </div></div>
    </div></main>
  </body></html>`,
    { url: 'https://docs.example/libmemalloc/api.html', runScripts: 'outside-only' },
  );
  const tools = new Map();
  const { window } = dom;

  try {
    Object.defineProperty(window, 'isSecureContext', { value: true });
    // Also cover the older navigator entry point and loading-document registration path.
    window.navigator.modelContext = { registerTool: (tool) => tools.set(tool.name, tool) };
    window.fetch = () => {
      throw new Error('Page tools must not fetch');
    };
    window.eval(source);
    await new Promise((resolve) => setImmediate(resolve));
    assert.equal(tools.size, 8);

    await verifyContracts(tools);

    const bodyBefore = window.document.body.innerHTML;
    const api = tools.get('libmemalloc_read_api_contract').execute;
    const contract = await api({ symbol: 'FIXTURE_allocate' });
    assert.equal(contract.status, 'found');
    assert.match(contract.signature, /void \* FIXTURE_allocate/);
    assert.equal(contract.url, 'https://docs.example/libmemalloc/api.html#allocate');
    assert.match(contract.text, /Caller owns/);
    assert.match(contract.text, /Count must be positive/);
    assert.match(contract.text, /NULL on failure/);
    assert.match(contract.text, /Requires external locking/);
    assert.doesNotMatch(contract.text, /Copy noise|Diagram noise|return value/);
    assert.equal((await api({ symbol: 'FIXTURE_allocate', limit: 10 })).nextOffset, 10);
    assert.equal(
      (await api({ symbol: 'FIXTURE_allocate', offset: 10, limit: 10 })).text,
      contract.text.slice(10, 20),
    );
    assert.equal((await api({ symbol: 'MISSING' })).status, 'not_found');
    await assert.rejects(api({ symbol: 'x;alert(1)' }));
    await assert.rejects(api({ symbol: 'x'.repeat(201) }));
    await assert.rejects(api({ symbol: 'MISSING', limit: 0 }));

    const example = tools.get('libmemalloc_read_code_example').execute;
    const literal = await example({});
    assert.equal(literal.total, 2);
    assert.equal(literal.language, 'c');
    assert.equal(literal.url, 'https://docs.example/libmemalloc/api.html#example');
    assert.equal(literal.text, 'int count = 1;\n  count += 2;');
    assert.equal((await example({ index: 1 })).text, 'int value;\nreturn value;');
    assert.equal((await example({ limit: 3 })).nextOffset, 3);
    assert.equal((await example({ offset: 3, limit: 4 })).text, literal.text.slice(3, 7));
    assert.equal((await example({ index: 99 })).status, 'not_found');
    await assert.rejects(example({ index: -1 }));
    await assert.rejects(example({ index: 99, offset: -1 }));

    const tree = tools.get('libmemalloc_accessibility_tree').execute;
    const snapshot = await tree({ limit: 200 });
    const named = (name) => snapshot.nodes.find((node) => node.name === name);
    assert.equal(snapshot.source, 'dom-semantics');
    assert.equal(snapshot.scanTruncated, false);
    assert.equal(named('Guide').parent, named('Documentation').id);
    assert.equal(named('Show contracts').states.expanded, 'false');
    assert.equal(named('Show contracts').relations.controls[0], 'contracts');
    assert.equal(named('Show contracts').relations.labeledBy[0], 'toggle-name');
    assert.equal(named('Find symbol').role, 'searchbox');
    assert.equal(named('Unavailable').states.disabled, true);
    assert.equal(named('Include internal').states.checked, true);
    assert.equal(named('Contract requirements').level, 3);
    assert.equal(named('Closed details').states.expanded, false);
    assert.equal(named('Unsafe address').url, null);
    for (const name of [
      'Hidden attribute',
      'Hidden ARIA',
      'Hidden CSS',
      'Inert subtree',
      'Closed child',
    ]) {
      assert.equal(named(name), undefined);
    }
    assert.doesNotMatch(JSON.stringify(snapshot), /typed-secret|password-secret/);
    assert.equal((await tree({ limit: 2 })).nextOffset, 2);
    assert.deepEqual(
      JSON.parse(JSON.stringify((await tree({ offset: 2, limit: 2 })).nodes)),
      JSON.parse(JSON.stringify(snapshot.nodes.slice(2, 4))),
    );
    assert.equal((await tree({ offset: 999 })).nextOffset, null);
    await assert.rejects(tree({ limit: 201 }));
    assert.equal(window.document.body.innerHTML, bodyBefore, 'Read tools must not mutate the page');

    window.document.querySelector('details').open = true;
    assert((await tree({ limit: 200 })).nodes.some((node) => node.name === 'Closed child'));
    const duplicate = window.document.querySelector('.memitem').cloneNode(true);
    window.document.querySelector('.contents').append(duplicate);
    assert.equal((await api({ symbol: 'FIXTURE_allocate' })).status, 'ambiguous');

    const oversized = window.document.createElement('a');
    oversized.id = 'x'.repeat(1000);
    oversized.href = `https://docs.example/${'x'.repeat(3000)}`;
    oversized.textContent = 'x'.repeat(1000);
    oversized.setAttribute('aria-controls', 'x'.repeat(1000));
    window.document.body.append(oversized);
    const bounded = (await tree({ limit: 200 })).nodes.find(
      (node) => node.name === 'x'.repeat(240),
    );
    assert.equal(bounded.domId, null);
    assert.equal(bounded.url, null);
    assert.equal(bounded.relations.controls.length, 0);

    // A pathological generated page must return a declared partial scan instead of walking forever.
    const large = window.document.createElement('div');
    large.innerHTML = '<span></span>'.repeat(10020);
    window.document.body.append(large);
    assert.equal((await tree({})).scanTruncated, true);

    large.remove();
    window.history.replaceState(null, '', '?access_token=url-secret#token-secret');
    const publicExamples = (await example({})).total;
    const privateContent = window.document.createElement('section');
    privateContent.innerHTML =
      '<textarea>textarea-secret</textarea>' +
      '<div contenteditable>editable-secret</div><div data-webmcp-private>' +
      '<h2>private-secret</h2><pre class="fragment">private-code</pre>' +
      '<span id="private-label">private-label-secret</span></div>' +
      '<button aria-labelledby="private-label" aria-label="Public label">Read</button>' +
      '<a href="https://user:credential-secret@other.example/">Credentials</a>' +
      '<a href="guide.html?token=query-secret#ownership">Public citation</a>';
    window.document.getElementById('doc-content').append(privateContent);

    const readResult = await tools.get('libmemalloc_read_page').execute({});
    const outlineResult = await tools.get('libmemalloc_page_outline').execute({});
    const treeResult = await tree({ limit: 200 });
    const serialized = JSON.stringify([readResult, outlineResult, treeResult]);

    for (const secret of [
      'textarea-secret',
      'editable-secret',
      'private-secret',
      'private-label-secret',
      'url-secret',
      'token-secret',
      'credential-secret',
      'query-secret',
    ]) {
      assert.equal(serialized.includes(secret), false, `Leaked fixture: ${secret}`);
    }
    assert.equal(treeResult.nodes.find((node) => node.name === 'Credentials').url, null);
    assert.equal(
      treeResult.nodes.find((node) => node.name === 'Public citation').url,
      'https://docs.example/libmemalloc/guide.html#ownership',
    );
    assert.equal((await example({ index: publicExamples })).status, 'not_found');
  } finally {
    window.close();
  }
}

(async () => {
  assert.equal((await environment({ supported: false })).tools.size, 0);
  assert.equal((await environment({ secure: false })).tools.size, 0);
  const denied = await environment({ fail: true });
  assert.equal(denied.warnings.length, 8, 'Registration failure must be handled per tool');
  const { tools, requests } = await environment();
  assert.equal(tools.size, 8);
  assert.equal(requests.length, 0, 'Catalog must not load until needed');
  for (const tool of tools.values()) {
    assert.equal(tool.annotations.readOnlyHint, true);
    assert.equal(tool.inputSchema.additionalProperties, false);
    await assert.rejects(tool.execute({ unexpected: 'argument' }));
    const controller = new AbortController();
    controller.abort();
    await assert.rejects(tool.execute({}, { signal: controller.signal }));
  }
  await verifyContracts(tools);
  const read = tools.get('libmemalloc_read_page').execute;
  const chunk = await read({ offset: 6, limit: 4 });
  assert.equal(chunk.text, 'line');
  assert.equal(chunk.nextOffset, 10);
  assert.equal((await read({ offset: 999 })).nextOffset, null);
  await assert.rejects(read({ limit: 20001 }));
  const search = tools.get('libmemalloc_search_documentation').execute;
  const result = await search({ query: 'ALLOCATOR', limit: 1 });
  assert.equal(result.total, 2, 'Ignore off-site and parent-directory catalog URLs');
  assert.equal(result.results.length, 1);
  assert.equal(result.results[0].url, 'https://docs.example/libmemalloc/guide.html');
  assert.equal(requests[0].url, 'https://docs.example/libmemalloc/documentation-index.json');
  assert.equal(requests[0].options.credentials, 'omit');
  assert.equal(requests[0].options.redirect, 'error');
  assert.equal(requests[0].options.mode, 'same-origin');
  assert.equal(requests[0].options.referrerPolicy, 'no-referrer');
  assert.equal((await search({ query: 'not found' })).total, 0);
  assert.equal(requests.length, 1, 'Successful catalog response should be reused');
  await assert.rejects(search({ query: ' ' }));
  await assert.rejects(search({ query: 'x'.repeat(201) }));
  await assert.rejects(search({ query: 'x', limit: -1 }));
  const found = await tools.get('libmemalloc_find_in_page').execute({ query: 'LINE', limit: 2 });
  assert.equal(found.results.length, 2);
  assert.equal(found.hasMore, true);
  await networkSecurity();
  await documentationTools();
  console.log(
    'WebMCP: feature detection, registration failures, validation, aborts, ' +
      'pagination, scoped search, output schemas, private content, network limits, ' +
      'API contracts, examples and semantic trees passed.',
  );
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

/* EOF */

