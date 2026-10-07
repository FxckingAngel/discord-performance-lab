import fs from 'node:fs/promises';

const [officialPath, trackBPath, outputPath] = process.argv.slice(2);
if (!officialPath || !trackBPath || !outputPath) {
  throw new Error('Usage: node tools/Compare-DiscordMediaQuality.mjs <official.json> <track-b.json> <output.json>');
}

const read = async (path) => JSON.parse((await fs.readFile(path, 'utf8')).replace(/^\uFEFF/, ''));
const official = await read(officialPath);
const trackB = await read(trackBPath);
const officialMedia = official.mediaQuality;
const trackBMedia = trackB.mediaQuality;
if (!officialMedia || !trackBMedia) throw new Error('Both reports must contain mediaQuality.');

const closeEnough = (a, b, relative = 0.1) => Number.isFinite(a) && Number.isFinite(b) && Math.abs(a - b) <= Math.max(1, Math.max(Math.abs(a), Math.abs(b)) * relative);
const metric = (side, name) => side.media?.[name]?.median;
const viewportScaleComparable = closeEnough(officialMedia.viewport?.devicePixelRatio, trackBMedia.viewport?.devicePixelRatio, 0.01)
  && closeEnough(officialMedia.viewport?.visualViewportScale, trackBMedia.viewport?.visualViewportScale, 0.01)
  && officialMedia.viewport?.innerWidth === trackBMedia.viewport?.innerWidth
  && officialMedia.viewport?.innerHeight === trackBMedia.viewport?.innerHeight;
const sourceResolutionComparable = closeEnough(metric(officialMedia, 'visibleNaturalWidth'), metric(trackBMedia, 'visibleNaturalWidth'))
  && closeEnough(metric(officialMedia, 'visibleNaturalHeight'), metric(trackBMedia, 'visibleNaturalHeight'));
const displayedSizeComparable = closeEnough(metric(officialMedia, 'visibleDisplayedWidth'), metric(trackBMedia, 'visibleDisplayedWidth'))
  && closeEnough(metric(officialMedia, 'visibleDisplayedHeight'), metric(trackBMedia, 'visibleDisplayedHeight'));
const qualityHintComparable = officialMedia.media?.requestedSourceHints?.qualityHintCount === trackBMedia.media?.requestedSourceHints?.qualityHintCount;
const featureStatus = (report) => report.gpu?.gpuInfo?.featureStatus ?? report.gpu?.featureStatus ?? null;
const hardwareAccelerationEnabled = (report) => {
  const status = featureStatus(report);
  if (!status) return false;
  const softwareStates = new Set(['disabled_off', 'unavailable_software', 'software']);
  const relevant = ['gpu_compositing', 'rasterization', 'video_decode', 'webgl', 'webgl2'].map((key) => status[key]).filter(Boolean);
  return relevant.length > 0 && relevant.every((value) => !softwareStates.has(value));
};
const officialHardware = hardwareAccelerationEnabled(official);
const trackBHardware = hardwareAccelerationEnabled(trackB);
const rasterQualityComparable = viewportScaleComparable && displayedSizeComparable && qualityHintComparable;
const result = {
  schemaVersion: 1,
  capturedAt: new Date().toISOString(),
  comparisonTool: 'Compare-DiscordMediaQuality.mjs',
  policy: 'Sanitized media-quality comparison. Only aggregate dimensions, scale values, GPU feature-status buckets, and boolean parity results are written. No URLs, page text, message data, cookies, tokens, or image pixels are written.',
  source: { official: officialPath, trackB: trackBPath },
  comparison: {
    sourceResolutionComparable,
    rasterQualityComparable,
    hardwareAccelerationEnabled: officialHardware && trackBHardware,
    officialHardwareAccelerationEnabled: officialHardware,
    trackBHardwareAccelerationEnabled: trackBHardware,
    visualQualityComparable: sourceResolutionComparable && rasterQualityComparable && officialHardware && trackBHardware,
    viewportScaleComparable,
    displayedSizeComparable,
    qualityHintComparable,
  },
};
await fs.writeFile(outputPath, JSON.stringify(result, null, 2), 'utf8');
console.log(JSON.stringify({ outputPath, comparison: result.comparison }));
