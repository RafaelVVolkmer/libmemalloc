/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-only
 */

/** Keep documentation navigation local and isolate external HTTP destinations. */
function installDocumentationNavigation(): void {
  const script = document.currentScript as HTMLScriptElement | null;
  const publication = new URL('.', script?.src || location.href);

  /** Set navigation policy at activation time, including links inserted later. */
  function prepareLink(event: Event): void {
    const element = event.target;

    if (!(element instanceof Element)) return;

    const anchor = element.closest('a[href]');

    if (!(anchor instanceof HTMLAnchorElement) || anchor.hasAttribute('download')) return;

    const destination = new URL(anchor.href, location.href);
    const internal =
      destination.origin === publication.origin &&
      destination.protocol === publication.protocol &&
      destination.pathname.startsWith(publication.pathname);

    if (internal) {
      anchor.removeAttribute('target');
      return;
    }

    if (destination.protocol === 'https:' || destination.protocol === 'http:') {
      anchor.target = '_blank';
      anchor.relList.add('noopener', 'noreferrer');
    }
  }

  document.addEventListener('click', prepareLink, true);
  document.addEventListener('auxclick', prepareLink, true);
}

installDocumentationNavigation();

// EOF

