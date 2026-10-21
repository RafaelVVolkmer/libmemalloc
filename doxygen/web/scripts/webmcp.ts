/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-only
 */

// Expose published libmemalloc contracts, examples and page semantics to WebMCP agents.
// This documentation adapter reads browser content; it does not execute native allocator code.
(() => {
  interface Page {
    title: string;
    url: string;
  }

  interface ExecutionOptions {
    signal?: AbortSignal;
  }

  interface Tool {
    name: string;
    description: string;
    inputSchema: object;
    annotations: { readOnlyHint: boolean; untrustedContentHint: boolean };
    execute(input: Record<string, unknown>, options?: ExecutionOptions): Promise<unknown>;
  }

  interface ModelContext {
    registerTool(tool: Tool): void | Promise<void>;
  }

  interface ContextHost {
    modelContext?: ModelContext;
  }

  const context =
    (document as Document & ContextHost).modelContext ||
    (navigator as Navigator & ContextHost).modelContext;

  if (!window.isSecureContext || typeof context?.registerTool !== 'function') return;

  const registerTool = context.registerTool.bind(context);
  const scriptURL =
    (document.currentScript as HTMLScriptElement | null)?.src ||
    new URL('webmcp.js', location.href).href;
  const catalogURL = new URL('documentation-index.json', scriptURL);

  // Bound tool output independently of the size of a generated documentation page.
  const limits = {
    textDefault: 12000,
    textMaximum: 20000,
    nameMaximum: 240,
    urlMaximum: 2048,
    treeDefault: 80,
    treeMaximum: 200,
    treeScanMaximum: 10000,
    relationMaximum: 16,
    catalogBytes: 2 * 1024 * 1024,
    catalogEntries: 10000,
    networkTimeoutMs: 5000,
    concurrentCalls: 4,
    outputCharacters: 512 * 1024,
    outlineMaximum: 1000,
  };

  // A script hosted elsewhere must not select the catalog origin for this page.
  if (catalogURL.origin !== new URL(location.href).origin) return;

  const excludedContent =
    'script, style, template, input, textarea, select, [contenteditable], ' +
    '[data-webmcp-private], [hidden], [inert], [aria-hidden="true"]';

  const annotations = { readOnlyHint: true, untrustedContentHint: true };

  // Reject undeclared inputs at both the schema and execution boundaries.
  const schema = (properties: Record<string, object> = {}, required: string[] = []) => ({
    type: 'object',
    properties,
    required,
    additionalProperties: false,
  });

  // Validate pagination before selecting or slicing page content.
  const integer = (value: unknown, fallback: number, minimum: number, maximum: number) => {
    if (value === undefined) return fallback;
    if (
      typeof value !== 'number' ||
      !Number.isInteger(value) ||
      value < minimum ||
      value > maximum
    ) {
      throw new TypeError(`Expected an integer between ${minimum} and ${maximum}.`);
    }
    return value;
  };

  // Normalize literal search terms without interpreting expressions.
  const queryText = (value: unknown) => {
    if (typeof value !== 'string' || !value.trim() || value.length > 200) {
      throw new TypeError('Query must contain between 1 and 200 characters.');
    }
    return value.trim().toLocaleLowerCase();
  };

  // Honor cancellation before accessing the DOM or loading the catalog.
  const check = (input: Record<string, unknown>, allowed: string[], signal?: AbortSignal) => {
    signal?.throwIfAborted();

    if (
      !input ||
      typeof input !== 'object' ||
      Array.isArray(input) ||
      Reflect.ownKeys(input).some((key) => {
        const descriptor = Object.getOwnPropertyDescriptor(input, key);

        return (
          typeof key !== 'string' ||
          !allowed.includes(key) ||
          !descriptor ||
          !('value' in descriptor)
        );
      }) ||
      allowed.some((key) => key in input && !Object.hasOwn(input, key))
    ) {
      throw new TypeError('Unexpected tool arguments.');
    }
  };

  // Keep documentation reads within the Doxygen content region.
  const main = () => {
    const element = document.getElementById('doc-content');

    if (!element) throw new Error('Documentation content is unavailable on this page.');

    return element;
  };

  // Remove excluded descendants from detached copies without changing the live page.
  function publicCopy(element: Element): Element {
    const copy = element.cloneNode(true) as Element;

    copy.querySelectorAll(excludedContent).forEach((node) => {
      node.remove();
    });

    return copy;
  }

  // Produce a citation without session parameters, credentials or arbitrary fragments.
  function pageURL(): string {
    const url = new URL(location.href);

    url.username = '';
    url.password = '';
    url.search = '';
    url.hash = '';

    return url.href;
  }

  // Prefer the authored title, using the same public-content boundary as text reads.
  function pageTitle(): string {
    const title =
      main().querySelector('.contents h1') || main().querySelector('.header h1, .header .title');

    if (!title || title.closest(excludedContent)) return 'libmemalloc';

    return publicCopy(title).textContent?.trim().slice(0, limits.nameMaximum) || 'libmemalloc';
  }

  // Exclude interactive chrome from prose chunks and search offsets.
  const pageText = () => {
    const content = publicCopy(main());
    content
      .querySelectorAll(
        'script, style, .lma-tools, button, .lma-status, ' +
          '#MSearchSelectWindow, #MSearchResultsWindow',
      )
      .forEach((element) => {
        element.remove();
      });

    return content.textContent?.trim() ?? '';
  };

  // Preserve heading levels and anchors in document order.
  const outline = () =>
    [...main().querySelectorAll('h1, h2, h3, h4, h5, h6, [role="heading"][aria-level]')]
      .filter(
        (heading) =>
          !heading.closest(excludedContent) &&
          !heading.closest('.lma-tools') &&
          !heading.closest('.lma-has-title .header'),
      )
      .slice(0, limits.outlineMaximum)
      .map((heading) => {
        const id = heading.id || heading.querySelector('a[id]')?.id;
        const url = new URL(pageURL());
        url.hash = id && id.length <= limits.nameMaximum && /^[A-Za-z0-9_.:-]+$/.test(id) ? id : '';

        return {
          level: integer(
            Number(heading.getAttribute('aria-level') || heading.tagName.slice(1)),
            1,
            1,
            Number.MAX_SAFE_INTEGER,
          ),
          title: publicCopy(heading).textContent?.trim().slice(0, limits.nameMaximum) ?? '',
          url: url.href,
        };
      });

  let catalog: Page[] | undefined;

  // Read the response incrementally so a missing or false Content-Length cannot bypass limits.
  async function readCatalog(response: Response, signal: AbortSignal): Promise<unknown> {
    if (
      !response.ok ||
      response.redirected ||
      response.url !== catalogURL.href ||
      !response.headers
        .get('content-type')
        ?.split(';')[0]
        .trim()
        .match(/^application\/json$/i)
    ) {
      throw new Error('Documentation index response rejected.');
    }

    const reader = response.body?.getReader();

    if (!reader) throw new Error('Documentation index body unavailable.');

    const decoder = new TextDecoder('utf-8', { fatal: true });
    let bytes = 0;
    let text = '';

    try {
      while (true) {
        signal.throwIfAborted();

        const chunk = await reader.read();

        if (chunk.done) break;
        bytes += chunk.value.byteLength;

        if (bytes > limits.catalogBytes) throw new Error('Documentation index exceeds size limit.');
        text += decoder.decode(chunk.value, { stream: true });
      }

      signal.throwIfAborted();
      text += decoder.decode();

      return JSON.parse(text);
    } finally {
      await reader.cancel();
      reader.releaseLock();
    }
  }

  // Cache only successful responses; cancellation or invalid data permits a later retry.
  async function pages(signal?: AbortSignal): Promise<Page[]> {
    if (catalog) return catalog;
    if (!['https:', 'http:'].includes(catalogURL.protocol)) {
      throw new Error('Documentation search requires HTTP(S).');
    }

    const controller = new AbortController();
    const abort = () => controller.abort();
    const timer = setTimeout(abort, limits.networkTimeoutMs);

    signal?.addEventListener('abort', abort, { once: true });
    if (signal?.aborted) abort();

    try {
      const response = await fetch(catalogURL, {
        signal: controller.signal,
        credentials: 'omit',
        redirect: 'error',
        mode: 'same-origin',
        referrerPolicy: 'no-referrer',
      });
      const entries = await readCatalog(response, controller.signal);

      if (!Array.isArray(entries) || entries.length > limits.catalogEntries) {
        throw new Error('Invalid documentation index.');
      }

      catalog = entries
        .filter(
          (entry): entry is Page =>
            typeof entry === 'object' &&
            entry !== null &&
            typeof entry.title === 'string' &&
            entry.title.length <= limits.nameMaximum &&
            typeof entry.url === 'string' &&
            entry.url.length <= limits.urlMaximum &&
            /^[\w.-]+\.html$/.test(entry.url),
        )
        .map((entry) => ({ title: entry.title, url: new URL(entry.url, catalogURL).href }));

      return catalog;
    } finally {
      clearTimeout(timer);
      signal?.removeEventListener('abort', abort);
    }
  }
  interface SemanticNode {
    id: number;
    parent: number | null;
    role: string;
    name: string;
    domId: string | null;
    url: string | null;
    level?: number;
    states: Record<string, string | boolean>;
    relations: Record<string, string[]>;
  }

  // Return citation links only for ordinary web documents and downloaded pages.
  function citation(value: string | null): string | null {
    if (!value || value.length > limits.urlMaximum) return null;

    try {
      const url = new URL(value, pageURL());

      if (url.username || url.password) return null;
      url.search = '';
      if (!/^#[A-Za-z0-9_.:-]+$/.test(url.hash)) url.hash = '';

      return url.href.length <= limits.urlMaximum &&
        ['https:', 'http:', 'file:'].includes(url.protocol)
        ? url.href
        : null;
    } catch {
      return null;
    }
  }

  // Remove Doxygen controls and line numbers without changing source whitespace.
  function literalCode(element: Element): string {
    const copy = publicCopy(element);

    copy.querySelectorAll('.lineno, .ttc, .foldclosed, .clipboard, button').forEach((node) => {
      node.remove();
    });

    const lines = [...copy.querySelectorAll('.line')];

    return lines.length
      ? lines.map((line) => line.textContent ?? '').join('\n')
      : (copy.textContent ?? '');
  }

  // Share the same continuation contract across prose, API and example reads.
  function textChunk(text: string, input: Record<string, unknown>) {
    const offset = integer(input.offset, 0, 0, Number.MAX_SAFE_INTEGER);
    const limit = integer(input.limit, limits.textDefault, 1, limits.textMaximum);

    return {
      text: text.slice(offset, offset + limit),
      totalCharacters: text.length,
      nextOffset: offset + limit < text.length ? offset + limit : null,
    };
  }

  // Find an exact C identifier in detailed Doxygen member sections on this page.
  function apiMembers(symbol: string) {
    return [...main().querySelectorAll('.memitem')].filter((member) => {
      if (member.closest(excludedContent)) return false;

      const declaration = member.querySelector('td.memname')?.textContent?.trim() ?? '';
      const identifier = declaration.match(/([A-Za-z_][A-Za-z0-9_]*)\s*$/)?.[1];

      return identifier === symbol;
    });
  }

  // Keep documented requirements and parameter tables; omit source and diagram copies.
  function contractText(member: Element): string {
    const original = member.querySelector('.memdoc');
    const description = original ? publicCopy(original) : undefined;

    if (!description) return '';

    description
      .querySelectorAll(
        '.fragment, .lma-code, .dynheader, .dyncontent, ' +
          '.dynsummary, .lma-graph-description, script, style',
      )
      .forEach((node) => {
        node.remove();
      });

    // Block separators keep table cells and adjacent requirements distinguishable.
    description.querySelectorAll('p, dt, dd, tr, td, th, li').forEach((node) => {
      node.append('\n');
    });

    return description.textContent?.trim() ?? '';
  }

  // Infer the native roles used by this site, preserving explicit ARIA roles.
  function semanticRole(element: Element): string | null {
    const explicit = element.getAttribute('role')?.trim().split(/\s+/)[0];

    if (explicit === 'none' || explicit === 'presentation') return null;
    if (explicit) return explicit.length <= limits.nameMaximum ? explicit : null;
    if (/^H[1-6]$/.test(element.tagName)) return 'heading';
    if (element.matches('a[href]')) return 'link';
    if (element.matches('img[alt=""]')) return null;
    if (element.matches('input[type="hidden"]')) return null;
    if (element.matches('input[type="checkbox"]')) return 'checkbox';
    if (element.matches('input[type="radio"]')) return 'radio';
    if (element.matches('input[type="button"], input[type="submit"], input[type="reset"]')) {
      return 'button';
    }
    if (element.matches('input[type="search"]')) return 'searchbox';

    const roles: Record<string, string> = {
      MAIN: 'main',
      NAV: 'navigation',
      ASIDE: 'complementary',
      BUTTON: 'button',
      SUMMARY: 'button',
      DETAILS: 'group',
      UL: 'list',
      OL: 'list',
      LI: 'listitem',
      TABLE: 'table',
      TR: 'row',
      TD: 'cell',
      TH: 'columnheader',
      IMG: 'img',
      INPUT: 'textbox',
      TEXTAREA: 'textbox',
      SELECT: 'combobox',
      OPTION: 'option',
    };

    return roles[element.tagName] ?? null;
  }

  // Summarize a subset of accessible-name sources; this is not the AccName algorithm.
  function semanticName(element: Element, role: string): string {
    const labeledBy =
      element
        .getAttribute('aria-labelledby')
        ?.trim()
        .split(/\s+/)
        .slice(0, limits.relationMaximum) ?? [];
    const referenced = labeledBy
      .map((id) => {
        const label = document.getElementById(id);

        return label &&
          !label.closest('[data-webmcp-private], [contenteditable], textarea, input, select')
          ? (publicCopy(label).textContent?.slice(0, limits.nameMaximum) ?? '')
          : '';
      })
      .join(' ')
      .trim();

    const label = element.getAttribute('aria-label');
    const labels = 'labels' in element ? (element as HTMLInputElement).labels : null;
    const nativeLabel = labels
      ? [...labels]
          .filter((item) => !item.closest('[data-webmcp-private]'))
          .map((item) => publicCopy(item).textContent?.slice(0, limits.nameMaximum) ?? '')
          .join(' ')
      : '';
    let text = referenced || label || nativeLabel || element.getAttribute('alt') || '';

    if (!text && ['heading', 'link', 'button', 'cell', 'columnheader', 'option'].includes(role)) {
      const copy = publicCopy(element);

      copy.querySelectorAll('[aria-hidden="true"], [hidden], script, style').forEach((node) => {
        node.remove();
      });

      text = copy.textContent ?? '';
    }

    return (text || element.getAttribute('title') || '')
      .replace(/\s+/g, ' ')
      .trim()
      .slice(0, limits.nameMaximum);
  }

  // Omit hidden subtrees and closed disclosure contents while retaining the summary.
  function excludedFromTree(element: Element): boolean {
    if (
      element.matches(
        'script, style, template, [data-webmcp-private], [contenteditable], ' +
          '[hidden], [inert], [aria-hidden="true"]',
      )
    ) {
      return true;
    }

    const style = window.getComputedStyle(element);

    return (
      style.display === 'none' || style.visibility === 'hidden' || style.visibility === 'collapse'
    );
  }

  // Report state without exposing typed values or changing focus, disclosure or navigation.
  function semanticStates(element: Element): Record<string, string | boolean> {
    const states: Record<string, string | boolean> = {};

    for (const name of ['expanded', 'pressed', 'checked', 'selected', 'disabled', 'current']) {
      const value = element.getAttribute(`aria-${name}`);

      if (value !== null) states[name] = value.slice(0, limits.nameMaximum);
    }

    if (element.matches(':disabled')) states.disabled = true;

    if (element.matches('input[type="checkbox"], input[type="radio"]')) {
      states.checked = (element as HTMLInputElement).checked;
    }
    if (element.matches('summary') && element.parentElement?.matches('details')) {
      states.expanded = element.parentElement.hasAttribute('open');
    }
    if (element === document.activeElement) states.focused = true;

    return states;
  }

  // Keep references to labels, descriptions and controlled panels alongside each node.
  function semanticRelations(element: Element): Record<string, string[]> {
    const relations: Record<string, string[]> = {};
    const attributes = {
      controls: 'aria-controls',
      labeledBy: 'aria-labelledby',
      describedBy: 'aria-describedby',
    };

    for (const [name, attribute] of Object.entries(attributes)) {
      const value = element.getAttribute(attribute)?.trim();

      if (value) {
        relations[name] = value
          .split(/\s+/)
          .slice(0, limits.relationMaximum)
          .filter((id) => id.length <= limits.nameMaximum);
      }
    }

    return relations;
  }

  // Flatten semantic ancestors into parent references with a bounded, iterative DOM walk.
  function semanticTree(signal?: AbortSignal) {
    const nodes: SemanticNode[] = [];
    const stack: { element: Element; parent: number | null }[] = [
      { element: document.body, parent: null },
    ];
    let scanned = 0;

    while (stack.length && scanned < limits.treeScanMaximum) {
      signal?.throwIfAborted();

      const entry = stack.pop();

      if (!entry) break;

      const { element, parent } = entry;

      scanned += 1;

      if (excludedFromTree(element)) continue;

      const role = semanticRole(element);
      let nextParent = parent;

      if (role) {
        const node: SemanticNode = {
          id: nodes.length,
          parent,
          role,
          name: semanticName(element, role),
          domId: element.id.length <= limits.nameMaximum ? element.id || null : null,
          url: citation(element.getAttribute('href')),
          states: semanticStates(element),
          relations: semanticRelations(element),
        };

        if (role === 'heading') {
          const level = Number(element.getAttribute('aria-level') || element.tagName.slice(1));

          if (Number.isInteger(level) && level > 0) node.level = level;
        }

        nodes.push(node);
        nextParent = node.id;
      }

      const children = element.matches('details:not([open])')
        ? [...element.children].filter((child) => child.matches('summary')).slice(0, 1)
        : [...element.children];

      for (const child of children.reverse()) stack.push({ element: child, parent: nextParent });
    }

    return { nodes, scanTruncated: stack.length > 0 };
  }

  const tools: Tool[] = [
    {
      name: 'libmemalloc_read_api_contract',
      description:
        'Read a documented C symbol on the current libmemalloc API page: declaration, ' +
        'contract text and citation. Includes authored ownership, failure and threading ' +
        'requirements when present; does not infer missing guarantees or execute C code.',
      inputSchema: schema(
        {
          symbol: { type: 'string', pattern: '^[A-Za-z_][A-Za-z0-9_]*$', maxLength: 200 },
          offset: { type: 'integer', minimum: 0, maximum: Number.MAX_SAFE_INTEGER },
          limit: { type: 'integer', minimum: 1, maximum: limits.textMaximum },
        },
        ['symbol'],
      ),
      annotations,
      async execute(input, { signal } = {}) {
        check(input, ['symbol', 'offset', 'limit'], signal);

        if (
          typeof input.symbol !== 'string' ||
          input.symbol.length > 200 ||
          !/^[A-Za-z_][A-Za-z0-9_]*$/.test(input.symbol)
        ) {
          throw new TypeError('Symbol must be an exact C identifier of at most 200 characters.');
        }

        // Validate pagination even when the current page has no matching symbol.
        textChunk('', input);

        const members = apiMembers(input.symbol);

        if (members.length !== 1) {
          return {
            symbol: input.symbol,
            url: pageURL(),
            status: members.length ? 'ambiguous' : 'not_found',
            matches: members.length,
          };
        }

        const member = members[0];
        const signature = member
          .querySelector('.memproto')
          ?.textContent?.replace(/\s+/g, ' ')
          .trim();

        const anchor = member.previousElementSibling?.querySelector('a[href]');

        return {
          status: 'found',
          symbol: input.symbol,
          signature: signature?.slice(0, limits.textMaximum) ?? '',
          signatureTruncated: (signature?.length ?? 0) > limits.textMaximum,
          url: citation(anchor?.getAttribute('href') ?? null) || pageURL(),
          ...textChunk(contractText(member), input),
        };
      },
    },
    {
      name: 'libmemalloc_read_code_example',
      description:
        'Read a zero-based code block from the current libmemalloc documentation page. ' +
        'Returns literal source, its language when declared, and a continuation offset. ' +
        'Removes Doxygen line numbers and controls; does not compile or execute examples.',
      inputSchema: schema({
        index: { type: 'integer', minimum: 0, maximum: Number.MAX_SAFE_INTEGER },
        offset: { type: 'integer', minimum: 0, maximum: Number.MAX_SAFE_INTEGER },
        limit: { type: 'integer', minimum: 1, maximum: limits.textMaximum },
      }),
      annotations,
      async execute(input, { signal } = {}) {
        check(input, ['index', 'offset', 'limit'], signal);

        const index = integer(input.index, 0, 0, Number.MAX_SAFE_INTEGER);
        const blocks = [...main().querySelectorAll('.fragment')].filter(
          (block) => !block.closest(excludedContent),
        );
        const block = blocks[index];

        textChunk('', input);

        if (!block) return { status: 'not_found', index, total: blocks.length, url: pageURL() };

        return {
          status: 'found',
          index,
          total: blocks.length,
          language:
            block
              .closest<HTMLElement>('.lma-code')
              ?.dataset.language?.slice(0, limits.nameMaximum) ?? null,
          url: block.id ? citation(`#${block.id}`) : pageURL(),
          ...textChunk(literalCode(block), input),
        };
      },
    },
    {
      name: 'libmemalloc_accessibility_tree',
      description:
        'Inspect a DOM-derived semantic tree of the current page: parent IDs, roles, ' +
        'name hints, heading levels, links and control states. Excludes hidden subtrees ' +
        'and typed values. This approximation is not the browser accessibility tree. ' +
        'IDs describe this snapshot; pagination assumes the DOM has not changed.',
      inputSchema: schema({
        offset: { type: 'integer', minimum: 0, maximum: Number.MAX_SAFE_INTEGER },
        limit: { type: 'integer', minimum: 1, maximum: limits.treeMaximum },
      }),
      annotations,
      async execute(input, { signal } = {}) {
        check(input, ['offset', 'limit'], signal);

        const offset = integer(input.offset, 0, 0, Number.MAX_SAFE_INTEGER);
        const limit = integer(input.limit, limits.treeDefault, 1, limits.treeMaximum);
        const { nodes, scanTruncated } = semanticTree(signal);

        return {
          source: 'dom-semantics',
          url: pageURL(),
          nodes: nodes.slice(offset, offset + limit),
          total: nodes.length,
          scanTruncated,
          nextOffset: offset + limit < nodes.length ? offset + limit : null,
        };
      },
    },

    {
      name: 'libmemalloc_read_page',
      description:
        'Read the current libmemalloc documentation page as text. Use ' +
        'offset and limit to read long pages in chunks; no navigation or ' +
        'UI state changes.',
      inputSchema: schema({
        offset: { type: 'integer', minimum: 0, maximum: Number.MAX_SAFE_INTEGER },
        limit: { type: 'integer', minimum: 1, maximum: 20000 },
      }),
      annotations,
      async execute(input, { signal } = {}) {
        check(input, ['offset', 'limit'], signal);

        const offset = integer(input.offset, 0, 0, Number.MAX_SAFE_INTEGER);
        const limit = integer(input.limit, limits.textDefault, 1, limits.textMaximum);
        const text = pageText();

        return {
          title: pageTitle(),
          url: pageURL(),
          text: text.slice(offset, offset + limit),
          totalCharacters: text.length,
          nextOffset: offset + limit < text.length ? offset + limit : null,
        };
      },
    },
    {
      name: 'libmemalloc_page_outline',
      description:
        'List headings and their links on the current libmemalloc page, ' +
        'including their heading levels.',
      inputSchema: schema(),
      annotations,
      async execute(input, { signal } = {}) {
        check(input, [], signal);

        return { title: pageTitle(), url: pageURL(), headings: outline() };
      },
    },
    {
      name: 'libmemalloc_find_in_page',
      description:
        'Find literal case-insensitive text in the current documentation ' +
        'page. Returns bounded excerpts and character offsets for use ' +
        'with libmemalloc_read_page.',
      inputSchema: schema(
        {
          query: { type: 'string', minLength: 1, maxLength: 200, pattern: '\\S' },
          limit: { type: 'integer', minimum: 1, maximum: 20 },
        },
        ['query'],
      ),
      annotations,
      async execute(input, { signal } = {}) {
        check(input, ['query', 'limit'], signal);

        const query = queryText(input.query);
        const limit = integer(input.limit, 10, 1, 20);
        const text = pageText();
        const lowered = text.toLocaleLowerCase();
        const results = [];
        let offset = lowered.indexOf(query);

        while (offset !== -1 && results.length < limit) {
          results.push({
            offset,
            excerpt: text.slice(Math.max(0, offset - 100), offset + query.length + 160),
          });
          offset = lowered.indexOf(query, offset + query.length);
        }
        return { url: pageURL(), results, hasMore: offset !== -1 };
      },
    },
    {
      name: 'libmemalloc_search_documentation',
      description:
        'Search published documentation page titles and file names, ' +
        'including API references. Returns links, not full-text search ' +
        'results. Fetches only the public same-origin catalog, without credentials.',
      inputSchema: schema(
        {
          query: { type: 'string', minLength: 1, maxLength: 200, pattern: '\\S' },
          limit: { type: 'integer', minimum: 1, maximum: 30 },
        },
        ['query'],
      ),
      annotations,
      async execute(input, { signal } = {}) {
        check(input, ['query', 'limit'], signal);

        const query = queryText(input.query);
        const limit = integer(input.limit, 10, 1, 30);
        const results = (await pages(signal)).filter((page) =>
          `${page.title} ${page.url}`.toLocaleLowerCase().includes(query),
        );
        signal?.throwIfAborted();

        return { results: results.slice(0, limit), total: results.length };
      },
    },
  ];

  // Describe structured results separately from the draft browser registration dictionary.
  function outputContracts(): Record<string, object> {
    const text = { type: 'string', maxLength: limits.textMaximum };
    const name = { type: 'string', maxLength: limits.nameMaximum };
    const url = { type: 'string', maxLength: limits.urlMaximum };
    const count = { type: 'integer', minimum: 0, maximum: Number.MAX_SAFE_INTEGER };
    const flag = { type: 'boolean' };
    const nullable = (value: object) => ({ anyOf: [value, { type: 'null' }] });
    const record = (properties: Record<string, object>) =>
      schema(properties, Object.keys(properties));
    const array = (items: object, maxItems: number) => ({ type: 'array', items, maxItems });
    const chunk = { text, totalCharacters: count, nextOffset: nullable(count) };
    const page = { title: name, url };
    const example = { index: count, total: count, url: nullable(url) };
    const symbol = { type: 'string', pattern: '^[A-Za-z_][A-Za-z0-9_]*$', maxLength: 200 };
    const states = schema(
      Object.fromEntries(
        ['expanded', 'pressed', 'checked', 'selected', 'disabled', 'current', 'focused'].map(
          (key) => [key, { anyOf: [name, flag] }],
        ),
      ),
    );
    const relations = schema(
      Object.fromEntries(
        ['controls', 'labeledBy', 'describedBy'].map((key) => [
          key,
          array(name, limits.relationMaximum),
        ]),
      ),
    );
    const node = schema(
      {
        id: count,
        parent: nullable(count),
        role: name,
        name,
        domId: nullable(name),
        url: nullable(url),
        level: { type: 'integer', minimum: 1 },
        states,
        relations,
      },
      ['id', 'parent', 'role', 'name', 'domId', 'url', 'states', 'relations'],
    );

    return {
      libmemalloc_read_page: record({ ...page, ...chunk }),
      libmemalloc_page_outline: record({
        ...page,
        headings: array(
          record({ level: { type: 'integer', minimum: 1 }, title: name, url }),
          limits.outlineMaximum,
        ),
      }),
      libmemalloc_find_in_page: record({
        url,
        results: array(record({ offset: count, excerpt: { type: 'string', maxLength: 460 } }), 20),
        hasMore: flag,
      }),
      libmemalloc_search_documentation: record({ results: array(record(page), 30), total: count }),
      libmemalloc_read_api_contract: {
        oneOf: [
          record({
            status: { const: 'found' },
            symbol,
            signature: text,
            signatureTruncated: flag,
            url,
            ...chunk,
          }),
          record({ status: { enum: ['not_found', 'ambiguous'] }, symbol, url, matches: count }),
        ],
      },
      libmemalloc_read_code_example: {
        oneOf: [
          record({ status: { const: 'found' }, ...example, language: nullable(name), ...chunk }),
          record({ status: { const: 'not_found' }, ...example }),
        ],
      },
      libmemalloc_accessibility_tree: record({
        source: { const: 'dom-semantics' },
        url,
        nodes: array(node, limits.treeMaximum),
        total: count,
        scanTruncated: flag,
        nextOffset: nullable(count),
      }),
    };
  }

  const outputs = outputContracts();
  const registered = new Set<string>();
  let activeCalls = 0;

  // Return a detached contract so callers cannot mutate subsequent discovery responses.
  function capabilities() {
    return JSON.parse(
      JSON.stringify({
        application: 'libmemalloc-documentation',
        contractVersion: '1.0.0',
        schemaDialect: 'http://json-schema.org/draft-07/schema#',
        transport: 'webmcp',
        specification: 'https://webmachinelearning.github.io/webmcp/',
        specificationReviewed: '2026-09-23',
        audience: 'public',
        authorization: 'none-public-documentation',
        audit: 'none-no-arguments-or-content-retained',
        limits,
        tools: tools
          .filter((tool) => registered.has(tool.name))
          .map((tool) => ({
            name: tool.name,
            version: '1.0.0',
            description: tool.description,
            inputSchema: tool.inputSchema,
            outputSchema: outputs[tool.name],
            effects:
              tool.name === 'libmemalloc_search_documentation'
                ? ['read-public-documentation', 'fetch-public-catalog']
                : ['read-public-documentation'],
            requiresConfirmation: false,
            annotations: tool.annotations,
          })),
      }),
    );
  }

  tools.push({
    name: 'libmemalloc_capabilities',
    description:
      'Discover versioned public documentation capabilities, input/output schemas, ' +
      'effects and limits. ' +
      'Metadata is not authorization. Returned documentation remains untrusted content.',
    inputSchema: schema(),
    annotations,
    async execute(input, { signal } = {}) {
      check(input, [], signal);

      return capabilities();
    },
  });

  // The manifest schema permits arbitrary JSON Schemas only in its schema-valued fields.
  outputs.libmemalloc_capabilities = schema(
    {
      application: { const: 'libmemalloc-documentation' },
      contractVersion: { const: '1.0.0' },
      schemaDialect: { const: 'http://json-schema.org/draft-07/schema#' },
      transport: { const: 'webmcp' },
      specification: { const: 'https://webmachinelearning.github.io/webmcp/' },
      specificationReviewed: { const: '2026-09-23' },
      audience: { const: 'public' },
      authorization: { const: 'none-public-documentation' },
      audit: { const: 'none-no-arguments-or-content-retained' },
      limits: schema(
        Object.fromEntries(Object.entries(limits).map(([key, value]) => [key, { const: value }])),
        Object.keys(limits),
      ),
      tools: {
        type: 'array',
        maxItems: tools.length,
        items: schema(
          {
            name: { type: 'string', enum: tools.map((tool) => tool.name) },
            version: { const: '1.0.0' },
            description: { type: 'string', maxLength: 1024 },
            inputSchema: { type: 'object' },
            outputSchema: { type: 'object' },
            effects: {
              type: 'array',
              maxItems: 2,
              items: { enum: ['read-public-documentation', 'fetch-public-catalog'] },
            },
            requiresConfirmation: { const: false },
            annotations: schema(
              { readOnlyHint: { const: true }, untrustedContentHint: { const: true } },
              ['readOnlyHint', 'untrustedContentHint'],
            ),
          },
          [
            'name',
            'version',
            'description',
            'inputSchema',
            'outputSchema',
            'effects',
            'requiresConfirmation',
            'annotations',
          ],
        ),
      },
    },
    [
      'application',
      'contractVersion',
      'schemaDialect',
      'transport',
      'specification',
      'specificationReviewed',
      'audience',
      'authorization',
      'audit',
      'limits',
      'tools',
    ],
  );

  // Bound concurrent calls and serialized output; browser checks are not an authorization boundary.
  function guarded(tool: Tool): Tool {
    return {
      ...tool,
      async execute(input, options = {}) {
        options.signal?.throwIfAborted();
        if (activeCalls >= limits.concurrentCalls)
          throw new Error('Too many concurrent documentation calls.');
        activeCalls += 1;

        try {
          const result = await tool.execute(input, options);

          options.signal?.throwIfAborted();
          if (JSON.stringify(result).length > limits.outputCharacters) {
            throw new Error('Documentation output exceeds size limit.');
          }

          return result;
        } finally {
          activeCalls -= 1;
        }
      },
    };
  }

  // A denied tool must not prevent independent tools from registering.
  async function register() {
    for (const tool of tools) {
      try {
        await registerTool(guarded(tool));
        registered.add(tool.name);
      } catch {
        console.warn(`WebMCP tool ${tool.name} could not be registered.`);
      }
    }
  }

  if (document.readyState === 'loading')
    document.addEventListener('DOMContentLoaded', register, { once: true });
  else register();
})();

/* EOF */

