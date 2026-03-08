#!/usr/bin/env node
// merge-overlay.js — deep-merges two JSON config files
// Usage: node merge-overlay.js <overlay.json> <base.json>
// Result: base.json is updated with overlay values merged in
// Called ONLY by android-setup.sh — never referenced by Railway startup

import { readFileSync, writeFileSync } from 'fs';

function deepMerge(base, overlay) {
  const result = { ...base };
  for (const [key, val] of Object.entries(overlay)) {
    if (val && typeof val === 'object' && !Array.isArray(val) &&
        base[key] && typeof base[key] === 'object' && !Array.isArray(base[key])) {
      result[key] = deepMerge(base[key], val);
    } else {
      result[key] = val;
    }
  }
  return result;
}

const [,, overlayPath, basePath] = process.argv;
if (!overlayPath || !basePath) {
  console.error('Usage: node merge-overlay.js <overlay.json> <base.json>');
  process.exit(1);
}

try {
  const base = JSON.parse(readFileSync(basePath, 'utf8'));
  const overlay = JSON.parse(readFileSync(overlayPath, 'utf8'));
  const merged = deepMerge(base, overlay);
  writeFileSync(basePath, JSON.stringify(merged, null, 2));
  console.log('[merge-overlay] Android overlay applied successfully');
} catch (err) {
  console.error('[merge-overlay] Error:', err.message);
  process.exit(1);
}
