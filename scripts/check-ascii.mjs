import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { extname } from 'node:path';

const assets = new Set(['.png', '.jpg', '.jpeg', '.jar', '.ico', '.ttf']);
const files = new Set(execFileSync('git', ['ls-files', '-co', '--exclude-standard', '-z']).toString().split('\0').filter(Boolean));
let failures = 0;
for (const file of files) {
  if (assets.has(extname(file).toLowerCase())) continue;
  const bytes = readFileSync(file);
  const offset = bytes.findIndex(byte => byte > 127);
  if (offset !== -1) { console.error(`${file}: non-ASCII byte at offset ${offset}`); failures++; }
}
if (failures) process.exitCode = 1;
else console.log(`ASCII check passed for ${files.size} project files (binary assets excluded).`);
