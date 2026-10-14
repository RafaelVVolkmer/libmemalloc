/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-only
 */

// Local, dependency-free enhancements; all authored content survives without JS.
(() => {
  const root = document.documentElement;
  const key = 'libmemalloc-color-scheme';
  const copyFeedbackDuration = 2500;
  let theme = 'system';

  try {
    const saved = localStorage.getItem(key);

    if (saved === 'light' || saved === 'dark') theme = saved;
  } catch {
    // Storage can be unavailable when reading a downloaded site.
  }

  // Apply a chosen palette before the page content paints.
  function applyTheme(value: string) {
    root.classList.toggle('light-mode', value === 'light');
    root.classList.toggle('dark-mode', value === 'dark');
  }

  applyTheme(theme);

  const icons = {
    copy:
      '<rect x="8" y="8" width="12" height="12"/><path d="M16 8V5a2 2 0 ' +
      '0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3"/>',
    check: '<path d="m5 12 4 4L19 6"/>',
    sun:
      '<circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M2 12h2m16 ' +
      '0h2M5 5l1.5 1.5m11 11L19 19M5 19l1.5-1.5m11-11L19 5"/>',
    moon: '<path d="M20 14.5A8.5 8.5 0 0 1 9.5 4 8.5 8.5 0 1 0 20 14.5Z"/>',
    left: '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M9 4v16m6-12-3 4 3 4"/>',
    right: '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M15 4v16m-6-12 3 4-3 4"/>',
  };

  // Keep decorative SVGs outside the accessible name of their controls.
  function icon(button: HTMLButtonElement, name: keyof typeof icons) {
    button.innerHTML =
      '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" ' +
      'stroke="currentColor" stroke-width="1.7" stroke-linecap="square" ' +
      'stroke-linejoin="miter" aria-hidden="true">' +
      icons[name] +
      '</svg>';
  }

  // Attach reading controls after the generated navigation and content exist.
  function initialize() {
    const content = document.querySelector('.contents .textblock');
    const main = document.getElementById('doc-content');
    const top = document.getElementById('top');
    const container = document.getElementById('container');
    const navigation = document.getElementById('side-nav');
    const mainNavigation = document.getElementById('main-nav');

    if (!main || !top || !container || !navigation || !mainNavigation) return;

    root.classList.add('lma-enhanced');
    main.setAttribute('role', 'main');
    main.setAttribute('aria-label', 'Documentation content');
    main.tabIndex = -1;

    const skip = document.createElement('a');
    skip.className = 'lma-skip';
    skip.href = '#doc-content';
    skip.textContent = 'Skip to content';
    skip.addEventListener('click', () => main.focus());
    document.body.prepend(skip);

    const searchFilter = document.getElementById('MSearchSelect');

    if (searchFilter) {
      searchFilter.setAttribute('role', 'button');
      searchFilter.setAttribute('aria-label', 'Filter search results');
      searchFilter.tabIndex = 0;
    }

    // Reapply names when Doxygen replaces search markup.
    const labelSearch = () => {
      document.getElementById('MSearchField')?.setAttribute('aria-label', 'Search documentation');
      document.getElementById('MSearchClose')?.setAttribute('aria-label', 'Close search results');
      document.getElementById('MSearchSelect')?.setAttribute('role', 'button');
      document.getElementById('MSearchSelect')?.setAttribute('aria-label', 'Filter search results');
    };
    labelSearch();
    new MutationObserver(labelSearch).observe(top, { childList: true, subtree: true });
    document.addEventListener('keydown', (event) => {
      if (
        event.target instanceof HTMLElement &&
        event.target.id === 'MSearchSelect' &&
        event.key === ' '
      ) {
        event.preventDefault();
        event.target.dispatchEvent(
          new KeyboardEvent('keydown', { key: 'Enter', keyCode: 13, bubbles: true }),
        );
      }
    });
    document.querySelector('#projectlogo img')?.setAttribute('alt', 'libmemalloc mascot');
    document
      .querySelectorAll('.contents h1, .contents h2, .contents h3')
      .forEach((heading, index) => {
        const anchor = heading.querySelector('a[id]');

        if (!heading.id) heading.id = anchor ? `${anchor.id}-heading` : `lma-heading-${index}`;
      });

    const controls = document.createElement('div');
    controls.className = 'lma-reading-controls';
    controls.setAttribute('role', 'group');
    controls.setAttribute('aria-label', 'Reading controls');
    container.before(controls);

    // Create a labeled disclosure control for one reading panel.
    const panelButton = (name: string, iconName: keyof typeof icons, target: string) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = `lma-panel-toggle lma-${name}-toggle`;
      button.setAttribute('aria-controls', target);
      icon(button, iconName);
      controls.append(button);

      return button;
    };

    // Recover independent panel preferences when storage is available.
    const readPreference = (name: string) => {
      try {
        return localStorage.getItem(`libmemalloc-${name}`) === 'closed';
      } catch {
        return false;
      }
    };

    // Persist a panel selection without requiring storage access.
    const savePreference = (name: string, closed: boolean) => {
      try {
        localStorage.setItem(`libmemalloc-${name}`, closed ? 'closed' : 'open');
      } catch {
        /* Panels still work without storage. */
      }
    };

    const mobile = matchMedia('(max-width: 767px)');
    const left = panelButton('navigation', 'left', 'side-nav');
    mainNavigation.setAttribute('aria-label', 'Documentation menu');
    navigation.setAttribute('role', 'navigation');
    navigation.setAttribute('aria-label', 'Documentation');

    // Label lazily inserted navigation branches with their current state.
    const labelTree = () => {
      navigation.querySelectorAll('.item > a').forEach((button) => {
        const item = button.closest('.item');
        const expanded = !!button.querySelector('.arrowhead.opened');
        const text = item?.querySelector('.label')?.textContent?.trim() || 'section';
        button.setAttribute('role', 'button');
        button.setAttribute('aria-label', `${expanded ? 'Collapse' : 'Expand'} ${text}`);
        button.setAttribute('aria-expanded', String(expanded));
      });
      navigation.querySelectorAll<HTMLAnchorElement>('.label a').forEach((link) => {
        link.title = link.textContent?.trim() ?? '';
      });
    };
    new MutationObserver(labelTree).observe(navigation, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['class'],
    });
    labelTree();
    navigation.addEventListener('keydown', (event) => {
      if (
        event.key === ' ' &&
        event.target instanceof HTMLElement &&
        event.target.matches('.item > a')
      ) {
        event.preventDefault();
        event.target.click();
      }
    });

    let leftClosed = readPreference('navigation');
    let mobileOpen = false;
    // Keep visual placement and announced expansion state in sync.
    const setNavigation = () => {
      if (mobile.matches) controls.after(mainNavigation);
      else top.append(mainNavigation);

      const expanded = mobile.matches ? mobileOpen : !leftClosed;
      root.classList.toggle('lma-left-collapsed', !mobile.matches && leftClosed);
      root.classList.toggle('lma-mobile-navigation', mobile.matches && mobileOpen);
      left.setAttribute('aria-expanded', String(expanded));
      left.setAttribute('aria-label', `${expanded ? 'Collapse' : 'Expand'} navigation`);
      left.title = left.getAttribute('aria-label') ?? '';
      left.setAttribute('aria-controls', mobile.matches ? 'main-nav' : 'side-nav');
    };
    left.addEventListener('click', () => {
      if (mobile.matches) mobileOpen = !mobileOpen;
      else {
        leftClosed = !leftClosed;
        savePreference('navigation', leftClosed);
      }
      setNavigation();

      if (mobile.matches && mobileOpen) controls.scrollIntoView({ block: 'start' });
    });
    mobile.addEventListener('change', () => {
      mobileOpen = false;
      setNavigation();
    });
    setNavigation();

    const tools = document.createElement('div');
    tools.className = 'lma-tools';
    const title = content?.querySelector(':scope > h1');

    if (title) {
      main.classList.add('lma-has-title');
      title.after(tools);
    } else {
      (content || main.querySelector('.contents') || main).prepend(tools);
    }

    // Reuse authored outlines instead of creating a second table of contents.
    let toc = content
      ? [...content.querySelectorAll<HTMLDetailsElement>(':scope > details')].find((item) =>
          /^(on this page|table of contents)$/i.test(
            item?.querySelector('summary')?.textContent?.trim() || '',
          ),
        )
      : undefined;

    if (!toc) {
      const headings = [...main.querySelectorAll('.contents h2, .contents h3')];

      if (headings.length) {
        toc = document.createElement('details');

        const summary = document.createElement('summary');
        summary.textContent = 'On this page';
        const list = document.createElement('ul');
        let section: HTMLLIElement | undefined;
        headings.forEach((heading, index) => {
          const anchor = heading.querySelector('a[id]');

          if (!heading.id && !anchor) heading.id = `lma-section-${index}`;
          const link = document.createElement('a');
          link.href = `#${heading.id || anchor?.id || ''}`;
          link.textContent = heading.textContent?.trim();

          const item = document.createElement('li');
          item.append(link);

          if (heading.tagName === 'H3' && section) {
            let children = section.querySelector('ul');

            if (!children) {
              children = document.createElement('ul');
              section.append(children);
            }
            children.append(item);
          } else {
            list.append(item);
            section = item;
          }
        });
        toc.append(summary, list);
      }
    }

    let collapseOutline: (() => void) | undefined;

    if (toc) {
      const outline = toc;
      outline.classList.add('lma-toc');
      tools.id = 'lma-page-outline';
      tools.append(toc);
      tools.setAttribute('role', 'navigation');
      tools.setAttribute('aria-label', 'On this page');
      main.classList.add('lma-has-outline');

      const desktopOutline = matchMedia('(min-width: 1200px)');
      const summary = outline.querySelector<HTMLElement>(':scope > summary');

      if (!summary) return;

      const right = panelButton('outline', 'right', tools.id);
      let rightClosed = readPreference('outline');
      let compactOpen = false;
      // Match the outline disclosure state to the active viewport.
      const setOutline = () => {
        const expanded = desktopOutline.matches ? !rightClosed : compactOpen;
        root.classList.toggle('lma-right-collapsed', desktopOutline.matches && rightClosed);
        tools.hidden = desktopOutline.matches && rightClosed;
        outline.open = expanded;
        summary.tabIndex = desktopOutline.matches ? -1 : 0;
        right.setAttribute('aria-expanded', String(expanded));
        right.setAttribute('aria-label', `${expanded ? 'Collapse' : 'Expand'} page outline`);
        right.title = right.getAttribute('aria-label') ?? '';
      };
      right.addEventListener('click', () => {
        if (desktopOutline.matches) {
          rightClosed = !rightClosed;
          savePreference('outline', rightClosed);
        } else compactOpen = !compactOpen;
        setOutline();

        if (!desktopOutline.matches && compactOpen) tools.scrollIntoView({ block: 'start' });
      });
      collapseOutline = () => {
        if (tools.contains(document.activeElement)) right.focus();

        if (desktopOutline.matches) {
          rightClosed = true;
          savePreference('outline', true);
        } else compactOpen = false;
        setOutline();
      };
      setOutline();
      desktopOutline.addEventListener('change', setOutline);
      summary.addEventListener('click', (event) => {
        if (desktopOutline.matches) event.preventDefault();
      });
      outline.addEventListener('toggle', () => {
        if (!desktopOutline.matches) {
          compactOpen = outline.open;
          right.setAttribute('aria-expanded', String(compactOpen));
          right.setAttribute('aria-label', `${compactOpen ? 'Collapse' : 'Expand'} page outline`);
        }
      });

      // Expose the active section and open its enclosing outline branches.
      const markLocation = () => {
        outline.querySelectorAll<HTMLAnchorElement>('a[href^="#"]').forEach((link) => {
          const active = link.hash === location.hash;

          if (active) {
            link.setAttribute('aria-current', 'location');

            let parent = link.closest('details');

            while (parent && parent !== outline) {
              parent.open = true;
              parent = parent.parentElement?.closest('details') ?? null;
            }
          } else link.removeAttribute('aria-current');
        });
      };
      markLocation();
      window.addEventListener('hashchange', markLocation);
    }

    const toggle = document.createElement('button');
    toggle.type = 'button';
    toggle.className = 'lma-theme-toggle';
    const preference = matchMedia('(prefers-color-scheme: dark)');

    // Resolve the effective theme from the explicit choice or system setting.
    const isDark = () => theme === 'dark' || (theme === 'system' && preference.matches);

    // Announce the action the theme button will perform next.
    const updateToggle = () => {
      const label = isDark() ? 'Switch to light theme' : 'Switch to dark theme';
      toggle.setAttribute('aria-label', label);
      toggle.title = label;
      icon(toggle, isDark() ? 'sun' : 'moon');
    };
    updateToggle();
    preference.addEventListener('change', updateToggle);
    toggle.addEventListener('click', () => {
      theme = isDark() ? 'light' : 'dark';
      applyTheme(theme);
      updateToggle();

      try {
        localStorage.setItem(key, theme);
      } catch {
        // The selection still applies for this page without persistence.
      }
    });
    left.after(toggle);
    document.addEventListener('keydown', (event) => {
      if (event.key !== 'Escape') return;

      if (tools.contains(document.activeElement)) collapseOutline?.();
      else if (navigation.contains(document.activeElement) || (mobile.matches && mobileOpen)) {
        left.focus();

        if (mobile.matches) mobileOpen = false;
        else {
          leftClosed = true;
          savePreference('navigation', true);
        }
        setNavigation();
      }
    });

    if (!toc) tools.remove();

    const status = document.createElement('span');
    status.className = 'lma-status';
    status.setAttribute('role', 'status');
    document.body.append(status);
    document.querySelectorAll<HTMLElement>('.contents .fragment').forEach((pre) => {
      let block = pre.closest<HTMLElement>('.lma-code');
      const language = block?.dataset.language || 'Code';

      if (!block) {
        block = document.createElement('div');
        block.className = 'lma-code';
        pre.before(block);
        block.append(pre);
      }
      pre.querySelectorAll('.clipboard').forEach((control) => {
        control.remove();
      });

      if (/[\u2500-\u257f]/u.test(pre.textContent ?? '')) {
        pre.classList.add('lma-preserve-layout');
      }
      pre.tabIndex = 0;
      pre.setAttribute('aria-label', `${language} code example`);

      const copy = document.createElement('button');
      copy.type = 'button';
      copy.className = 'lma-copy';
      icon(copy, 'copy');
      copy.setAttribute('aria-label', `Copy ${language} code`);
      copy.title = 'Copy code';
      let reset: ReturnType<typeof setTimeout> | undefined;
      copy.addEventListener('click', async () => {
        clearTimeout(reset);
        copy.disabled = true;
        status.textContent = '';

        try {
          const contents = pre.cloneNode(true) as HTMLElement;
          contents.querySelectorAll('.lineno, .ttc, .foldclosed').forEach((node) => {
            node.remove();
          });
          await navigator.clipboard.writeText(contents.textContent ?? '');
          icon(copy, 'check');
          copy.title = 'Copied';
          status.textContent = 'Code copied to clipboard.';
        } catch {
          const selection = window.getSelection();
          const range = document.createRange();
          range.selectNodeContents(pre);
          selection?.removeAllRanges();
          selection?.addRange(range);
          pre.focus();
          copy.title = 'Code selected; use your device’s copy command';
          status.textContent =
            'Clipboard unavailable. Code selected; use your device’s copy command.';
        } finally {
          copy.disabled = false;
          reset = setTimeout(() => {
            icon(copy, 'copy');
            copy.title = 'Copy code';
          }, copyFeedbackDuration);
        }
      });
      block.append(copy);
    });

    // Wide reference tables scroll independently, including with a keyboard.
    document
      .querySelectorAll(
        '.contents table.markdownTable, .contents table.doxtable, .contents table.fieldtable',
      )
      .forEach((table) => {
        const wrapper = document.createElement('div');
        wrapper.className = 'lma-table-scroll';
        wrapper.tabIndex = 0;
        wrapper.setAttribute('role', 'region');
        wrapper.setAttribute('aria-label', 'Scrollable reference table');
        table.before(wrapper);
        wrapper.append(table);
      });

    document.querySelectorAll<HTMLElement>('.mermaidgraph').forEach((diagram) => {
      diagram.tabIndex = 0;
      diagram.setAttribute('role', 'region');
      diagram.setAttribute('aria-label', 'Diagram');
    });
    enhanceGraphs();
  }

  // Supply text alternatives and keyboard disclosure for generated graphs.
  function enhanceGraphs() {
    // Preserve the author's notation as a non-visual alternative while Mermaid renders.
    document.querySelectorAll('.mermaidgraph pre.mermaid').forEach((pre) => {
      const details = document.createElement('details');
      details.className = 'lma-graph-description';
      const summary = document.createElement('summary');
      summary.textContent = 'Diagram text';
      const source = document.createElement('pre');
      source.textContent = pre.textContent;
      details.append(summary, source);
      pre.closest('.mermaidgraph')?.after(details);
    });
    document.querySelectorAll('.lma-native-graph').forEach((graph) => {
      const section = graph.closest('.dyncontent');
      const header = section?.previousElementSibling;
      const label = header?.classList.contains('dynheader')
        ? header.textContent?.trim() || 'Doxygen graph'
        : 'Doxygen graph';
      graph.setAttribute('aria-label', label);
      graph.querySelector('svg')?.setAttribute('aria-label', label);

      const nodes = new Map();
      graph.querySelectorAll('.node').forEach((node) => {
        const key = node.querySelector('title')?.textContent;
        const text = [...node.querySelectorAll('text')].map((item) => item.textContent).join(' ');

        if (key) nodes.set(key, text);
        node.querySelector('a[href]')?.setAttribute('aria-label', text);
      });

      const details = document.createElement('details');
      details.className = 'lma-graph-description';
      const summary = document.createElement('summary');
      summary.textContent = 'Graph relationships';
      const list = document.createElement('ul');
      graph.querySelectorAll('.edge > title').forEach((edge) => {
        const [from, to] = (edge.textContent ?? '').split('->');
        const item = document.createElement('li');
        item.textContent = `${nodes.get(from) || from} → ${nodes.get(to) || to}`;
        list.append(item);
      });

      if (!list.children.length)
        nodes.forEach((text) => {
          const item = document.createElement('li');
          item.textContent = text;
          list.append(item);
        });
      details.append(summary, list);
      graph.after(details);
    });
    document.querySelectorAll<HTMLElement>('.dynheader').forEach((header) => {
      header.setAttribute('role', 'button');
      header.tabIndex = 0;
      const content = document.getElementById(`${header.id.replace(/-header$/, '')}-content`);

      if (!content) return;
      header.setAttribute('aria-controls', content.id);

      const update = () =>
        header.setAttribute('aria-expanded', String(!content.classList.contains('hidden')));
      update();
      new MutationObserver(update).observe(content, {
        attributes: true,
        attributeFilter: ['class', 'style'],
      });
      header.addEventListener('keydown', (event) => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          header.click();
        }
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize, { once: true });
  } else {
    initialize();
  }
})();

/* EOF */

