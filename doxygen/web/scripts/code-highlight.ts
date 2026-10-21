/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-only
 */

// Doxygen keeps examples literal; only their presentation changes here.
(() => {
  interface Highlighter {
    registerLanguage(name: string, grammar: unknown): void;
    getLanguage(name: string): unknown;
    highlightElement(element: HTMLElement): void;
  }

  const blocks = [...document.querySelectorAll<HTMLElement>('.lma-code[data-language]')];
  const loader = document.querySelector<HTMLScriptElement>('script[data-highlight-base]');
  const languages = new Set([
    'c',
    'cpp',
    'rust',
    'lua',
    'bash',
    'cmake',
    'yaml',
    'json',
    'python',
    'javascript',
    'ini',
    'diff',
    'xml',
    'css',
    'markdown',
  ]);

  // Load only the grammars declared by authored examples on this page.
  async function highlightExamples() {
    if (!blocks.length || !loader) return;

    const base = loader.dataset.highlightBase;

    if (!base) return;

    const { default: hljs }: { default: Highlighter } = await import(`${base}core.min.js`);
    const selected = [
      ...new Set(
        blocks
          .map((block) => block.dataset.language)
          .filter((language): language is string => typeof language === 'string'),
      ),
    ];

    await Promise.all(
      selected
        .filter((language) => languages.has(language))
        .map(async (language) => {
          try {
            const { default: grammar } = await import(`${base}languages/${language}.min.js`);
            hljs.registerLanguage(language, grammar);
          } catch (error) {
            console.warn(`Code highlighting unavailable for ${language}.`, error);
          }
        }),
    );

    for (const block of blocks) {
      const language = block.dataset.language;
      const pre = block.querySelector('pre.fragment');

      if (!pre || !language || !hljs.getLanguage(language)) continue;

      const code = document.createElement('code');
      code.className = `language-${language}`;
      code.textContent = pre.textContent;
      pre.replaceChildren(code);
      hljs.highlightElement(code);
    }
  }

  highlightExamples().catch((error) => {
    console.warn('Code highlighting unavailable; literal examples remain readable.', error);
  });
})();

/* EOF */

