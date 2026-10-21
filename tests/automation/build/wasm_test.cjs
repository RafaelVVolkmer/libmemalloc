/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-only
 */
const assert = require('node:assert/strict');
const fs = require('node:fs');

/** Execute the actual exported C ABI through a WebAssembly runtime. */
async function main() {
  const { instance } = await WebAssembly.instantiate(fs.readFileSync(process.argv[2]));

  assert.equal(instance.exports.LMA_compatibility(), 0);
  console.log('WebAssembly C ABI: passed');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// EOF

