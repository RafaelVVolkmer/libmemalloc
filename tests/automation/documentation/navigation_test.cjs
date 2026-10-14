/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-only
 */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

/** Model native link attributes while executing the published navigation script. */
class Anchor {
  constructor(href) {
    this.href = href;
    this.target = '_blank';
    this.relations = new Set();
    this.relList = {
      add: (...tokens) =>
        tokens.forEach((token) => {
          this.relations.add(token);
        }),
    };
  }

  closest() {
    return this;
  }
  hasAttribute() {
    return false;
  }
  removeAttribute(name) {
    delete this[name];
  }
}

/** Cover project subpaths, external origins, fragments and special protocols. */
function main() {
  const handlers = new Map();
  const source = fs.readFileSync(
    process.env.LIBMEMALLOC_NAVIGATION_ASSET || '.cache/docs/web/navigation.js',
    'utf8',
  );

  vm.runInNewContext(source, {
    document: {
      currentScript: { src: 'https://example.github.io/libmemalloc/navigation.js' },
      addEventListener: (name, callback) => handlers.set(name, callback),
    },
    location: { href: 'https://example.github.io/libmemalloc/guide.html' },
    Element: Anchor,
    HTMLAnchorElement: Anchor,
    URL,
  });

  for (const href of ['#details', 'api.html', 'https://example.github.io/libmemalloc/index.html']) {
    const link = new Anchor(href);
    handlers.get('click')({ target: link });
    assert.equal(link.target, undefined);
  }

  for (const href of [
    'https://example.org/',
    'https://example.github.io/another/',
    '//other.example/',
  ]) {
    const link = new Anchor(href);
    handlers.get('auxclick')({ target: link });
    assert.equal(link.target, '_blank');
    assert(link.relations.has('noopener') && link.relations.has('noreferrer'));
  }

  const mail = new Anchor('mailto:maintainer@example.org');
  delete mail.target;
  handlers.get('click')({ target: mail });
  assert.equal(mail.target, undefined);
  console.log('Documentation navigation: internal and external boundaries passed');
}

main();

// EOF

