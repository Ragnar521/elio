// scripts/sync-notion.js
// Syncs Elio code documentation to Notion on every push to main.
// Updates: file structure, data models, README → corresponding Notion pages.

const { Client } = require('@notionhq/client');
const fs = require('fs');
const path = require('path');

// ---------- Configuration ----------
const NOTION_TOKEN = process.env.NOTION_TOKEN;
const TECH_PLANNING_PAGE_ID = '2fdac827-11f0-81ec-8128-dd74568fbd3a';
const README_PAGE_ID = '357ac827-11f0-8156-9089-ff8efceda87e';

const REPO_ROOT = path.resolve(__dirname, '..');
const LIB_DIR = path.join(REPO_ROOT, 'lib');
const MODELS_DIR = path.join(LIB_DIR, 'models');
const README_PATH = path.join(REPO_ROOT, 'README.md');

if (!NOTION_TOKEN) {
  console.error('❌ NOTION_TOKEN env var is missing.');
  process.exit(1);
}

const notion = new Client({ auth: NOTION_TOKEN });

// ---------- 1. Build the lib/ file tree ----------
function buildFileTree(dir, prefix = '', isRoot = true) {
  let lines = [];
  if (isRoot) lines.push(path.basename(dir) + '/');

  const entries = fs.readdirSync(dir, { withFileTypes: true })
    .filter(e => !e.name.startsWith('.') && e.name !== 'node_modules')
    .sort((a, b) => {
      // directories first, then files; alphabetical within
      if (a.isDirectory() && !b.isDirectory()) return -1;
      if (!a.isDirectory() && b.isDirectory()) return 1;
      return a.name.localeCompare(b.name);
    });

  entries.forEach((entry, i) => {
    const isLast = i === entries.length - 1;
    const branch = isLast ? '└── ' : '├── ';
    const extension = isLast ? '    ' : '│   ';
    const suffix = entry.isDirectory() ? '/' : '';
    lines.push(prefix + branch + entry.name + suffix);
    if (entry.isDirectory()) {
      lines = lines.concat(
        buildFileTree(path.join(dir, entry.name), prefix + extension, false)
      );
    }
  });

  return lines;
}

// ---------- 2. Parse Hive @HiveType classes from models/ ----------
function parseDataModels() {
  const files = fs.readdirSync(MODELS_DIR).filter(f => f.endsWith('.dart'));
  const models = [];

  for (const file of files) {
    const content = fs.readFileSync(path.join(MODELS_DIR, file), 'utf8');
    // Match: class ClassName extends ... { ... @HiveField(N) Type fieldName; ... }
    const classMatch = content.match(/class\s+(\w+)\s+extends\s+HiveObject\s*{([\s\S]*?)^}/m);
    if (!classMatch) continue;

    const className = classMatch[1];
    const body = classMatch[2];

    const fieldRegex = /@HiveField\(\d+\)\s+(?:late\s+)?(\w+(?:<[^>]+>)?\??)\s+(\w+)\s*;/g;
    const fields = [];
    let m;
    while ((m = fieldRegex.exec(body)) !== null) {
      fields.push({ type: m[1], name: m[2] });
    }

    if (fields.length > 0) {
      models.push({ className, fields, file });
    }
  }
  return models;
}

function formatModelsAsCodeBlock(models) {
  let out = '';
  for (const m of models) {
    out += `${m.className} {\n`;
    for (const f of m.fields) {
      out += `  ${f.name}: ${f.type}\n`;
    }
    out += `}\n\n`;
  }
  return out.trim();
}

// ---------- 3. Notion block helpers ----------
async function getPageBlocks(pageId) {
  const blocks = [];
  let cursor;
  do {
    const res = await notion.blocks.children.list({
      block_id: pageId,
      start_cursor: cursor,
      page_size: 100,
    });
    blocks.push(...res.results);
    cursor = res.has_more ? res.next_cursor : undefined;
  } while (cursor);
  return blocks;
}

async function deleteAllChildren(pageId) {
  const blocks = await getPageBlocks(pageId);
  for (const b of blocks) {
    try {
      await notion.blocks.delete({ block_id: b.id });
    } catch (err) {
      console.warn(`  ⚠️  Could not delete block ${b.id}: ${err.message}`);
    }
  }
}

function codeBlock(text, language = 'plain text') {
  // Notion limits a single rich_text item to 2000 chars.
  const chunks = [];
  for (let i = 0; i < text.length; i += 2000) {
    chunks.push({ type: 'text', text: { content: text.slice(i, i + 2000) } });
  }
  return {
    object: 'block',
    type: 'code',
    code: { rich_text: chunks, language },
  };
}

function paragraph(text) {
  return {
    object: 'block',
    type: 'paragraph',
    paragraph: { rich_text: [{ type: 'text', text: { content: text } }] },
  };
}

function heading2(text) {
  return {
    object: 'block',
    type: 'heading_2',
    heading_2: { rich_text: [{ type: 'text', text: { content: text } }] },
  };
}

function divider() {
  return { object: 'block', type: 'divider', divider: {} };
}

// ---------- 4. Sync the README page ----------
async function syncReadme() {
  console.log('📄 Syncing README...');
  if (!fs.existsSync(README_PATH)) {
    console.log('  ⏭  No README.md found, skipping.');
    return;
  }

  const md = fs.readFileSync(README_PATH, 'utf8');
  const timestamp = new Date().toISOString().split('T')[0];

  await deleteAllChildren(README_PAGE_ID);

  const blocks = [
    paragraph(`Auto-synced from README.md on ${timestamp}. Manual edits will be overwritten.`),
    divider(),
    // Render the README as a single code block to preserve markdown exactly.
    // Future improvement: parse markdown into proper Notion blocks.
    codeBlock(md, 'markdown'),
  ];

  await notion.blocks.children.append({
    block_id: README_PAGE_ID,
    children: blocks,
  });
  console.log('  ✅ README page updated.');
}

// ---------- 5. Sync the Technical Planning page (selective) ----------
async function syncTechnicalPlanning() {
  console.log('💻 Syncing Technical Planning (file structure + data models)...');

  const tree = buildFileTree(LIB_DIR).join('\n');
  const models = parseDataModels();
  const modelsText = formatModelsAsCodeBlock(models);
  const timestamp = new Date().toISOString().split('T')[0];

  // Find existing auto-synced section by marker, or append at end.
  const blocks = await getPageBlocks(TECH_PLANNING_PAGE_ID);
  const markerText = '🤖 Auto-synced from code';
  let markerIndex = -1;

  for (let i = 0; i < blocks.length; i++) {
    const b = blocks[i];
    if (b.type === 'heading_2' && b.heading_2?.rich_text?.[0]?.plain_text?.includes(markerText)) {
      markerIndex = i;
      break;
    }
  }

  // If marker exists, delete it and everything after it.
  if (markerIndex >= 0) {
    const toDelete = blocks.slice(markerIndex);
    for (const b of toDelete) {
      try {
        await notion.blocks.delete({ block_id: b.id });
      } catch (err) {
        console.warn(`  ⚠️  Could not delete block ${b.id}: ${err.message}`);
      }
    }
  }

  // Append fresh auto-synced section at the end.
  const newBlocks = [
    divider(),
    heading2(`🤖 Auto-synced from code · ${timestamp}`),
    paragraph('The sections below are regenerated automatically on every push to main. Do not edit them by hand — your changes will be overwritten.'),
    heading2('File Structure (lib/)'),
    codeBlock(tree),
    heading2('Data Models'),
    paragraph(`Parsed from ${models.length} Hive class${models.length === 1 ? '' : 'es'} in lib/models/.`),
    codeBlock(modelsText || '(no models found)'),
  ];

  await notion.blocks.children.append({
    block_id: TECH_PLANNING_PAGE_ID,
    children: newBlocks,
  });
  console.log(`  ✅ Technical Planning updated. ${models.length} models, ${tree.split('\n').length} tree lines.`);
}

// ---------- Main ----------
(async () => {
  try {
    await syncReadme();
    await syncTechnicalPlanning();
    console.log('\n🎉 All Notion pages synced successfully.');
  } catch (err) {
    console.error('❌ Sync failed:', err.message);
    if (err.body) console.error(err.body);
    process.exit(1);
  }
})();