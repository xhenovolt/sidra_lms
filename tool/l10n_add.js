// Adds or updates app strings in both languages.
//   node tool/l10n_add.js strings.json      then: flutter gen-l10n
// strings.json: {"key": ["English", "العربية", {optional @metadata}]}
const fs = require('fs');
const t = JSON.parse(fs.readFileSync(process.argv[2], 'utf8').replace(/^﻿/, ''));
for (const [path, idx, meta] of [['lib/l10n/app_en.arb', 0, true], ['lib/l10n/app_ar.arb', 1, false]]) {
  const arb = JSON.parse(fs.readFileSync(path, 'utf8').replace(/^﻿/, ''));
  for (const [k, v] of Object.entries(t)) { arb[k] = v[idx]; if (meta && v[2]) arb['@' + k] = v[2]; }
  fs.writeFileSync(path, JSON.stringify(arb, null, 2) + '\n');
}
console.log('added', Object.keys(t).length);
