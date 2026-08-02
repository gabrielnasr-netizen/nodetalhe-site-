const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const videosDir = path.join(root, 'assets', 'videos');
const contentPath = path.join(root, 'data', 'content.json');

// key -> which content.json array field it belongs to
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

const content = JSON.parse(fs.readFileSync(contentPath, 'utf8'));
const existingIds = new Set(content.items.map(i => i.id));

const folders = fs.readdirSync(videosDir).filter(f => fs.statSync(path.join(videosDir, f)).isDirectory());

let added = 0;
for (const key of folders) {
  const field = KEY_FIELD[key];
  if (!field) { console.warn('No field mapping for folder', key); continue; }
  const dir = path.join(videosDir, key);
  const files = fs.readdirSync(dir).filter(f => f.endsWith('.mp4')).sort();
  files.forEach((file, idx) => {
    const id = `local-${key}-${idx + 1}`;
    if (existingIds.has(id)) return;
    const item = {
      id,
      localVideo: `assets/videos/${key}/${file}`,
      mediaType: 'VIDEO',
      date: null,
      title: `Reel ${idx + 1}`,
      captionShort: '',
      caption: '',
      competitions: field === 'competitions' ? [key] : [],
      partners: field === 'partners' ? [key] : [],
    };
    content.items.push(item);
    existingIds.add(id);
    added++;
  });
}

fs.writeFileSync(contentPath, JSON.stringify(content, null, 2) + '\n');
console.log(`Added ${added} local video items. Total items: ${content.items.length}`);
