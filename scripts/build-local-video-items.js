// Regenerates data/content.json from whatever video files actually exist
// under assets/videos/<category>/. Safe to re-run any number of times:
// - existing items are matched by their video file path and kept exactly
//   as they are (any hand-edited title/caption/date/reach survives)
// - new files (never seen before) get a default placeholder entry
// - items whose file was deleted are removed
// - non-local items (e.g. items without `localVideo`) are left untouched
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const videosDir = path.join(root, 'assets', 'videos');
const contentPath = path.join(root, 'data', 'content.json');

// folder name -> which content.json array field that category belongs to
const KEY_FIELD = {
  'copa-mundo': 'competitions',
  'libertadores': 'competitions',
  'brasileirao': 'competitions',
  'copa-brasil': 'competitions',
  'eliminatorias': 'competitions',
  'selecao': 'competitions',
  'internacionais': 'competitions',
  'paulistao': 'competitions',
  'sua-foto-no-jogo': 'competitions',
  '433': 'partners',
  'botafogo': 'partners',
  'fabrizio': 'partners',
  'tnt': 'partners',
};

const VIDEO_EXT = new Set(['.mp4', '.mov', '.webm', '.m4v']);

function slugifyFilename(file) {
  return path.basename(file, path.extname(file))
    .toLowerCase()
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '') || 'video';
}

const content = fs.existsSync(contentPath)
  ? JSON.parse(fs.readFileSync(contentPath, 'utf8'))
  : { items: [] };

// index existing items by their video path, so renamed ids / old naming
// schemes never cause an existing item to look "new"
const existingByPath = new Map(
  content.items.filter(i => i.localVideo).map(i => [i.localVideo, i])
);
const usedIds = new Set(content.items.map(i => i.id));

const folders = fs.existsSync(videosDir)
  ? fs.readdirSync(videosDir).filter(f => fs.statSync(path.join(videosDir, f)).isDirectory())
  : [];

const seenPaths = new Set();
const regenerated = [];
let added = 0, kept = 0, unknownFolders = [];

for (const key of folders) {
  const field = KEY_FIELD[key];
  if (!field) { unknownFolders.push(key); continue; }
  const dir = path.join(videosDir, key);
  const files = fs.readdirSync(dir)
    .filter(f => VIDEO_EXT.has(path.extname(f).toLowerCase()))
    .sort();

  const existingCountForKey = content.items.filter(i => i.localVideo &&
    (field === 'competitions' ? (i.competitions || []) : (i.partners || [])).includes(key)
  ).length;
  let nextReelNumber = existingCountForKey + 1;

  files.forEach(file => {
    const localVideo = `assets/videos/${key}/${file}`;
    seenPaths.add(localVideo);
    const existing = existingByPath.get(localVideo);
    if (existing) {
      regenerated.push(existing);
      kept++;
      return;
    }
    let id = `local-${key}-${slugifyFilename(file)}`;
    while (usedIds.has(id)) id += '-x';
    usedIds.add(id);
    regenerated.push({
      id,
      localVideo,
      mediaType: 'VIDEO',
      date: null,
      title: `Reel ${nextReelNumber++}`,
      captionShort: '',
      caption: '',
      competitions: field === 'competitions' ? [key] : [],
      partners: field === 'partners' ? [key] : [],
    });
    added++;
  });
}

// keep any items that aren't local videos untouched (e.g. future Instagram items)
const nonLocalItems = content.items.filter(i => !i.localVideo);
const removed = content.items.filter(i => i.localVideo && !seenPaths.has(i.localVideo)).length;

content.items = [...nonLocalItems, ...regenerated];

fs.writeFileSync(contentPath, JSON.stringify(content, null, 2) + '\n');

console.log(`content.json regenerated: ${added} added, ${kept} kept, ${removed} removed.`);
if (unknownFolders.length) {
  console.warn('Skipped folders with no category mapping:', unknownFolders.join(', '));
}
