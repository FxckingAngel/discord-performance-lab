import fs from 'node:fs/promises';

const rawPath = process.argv[2];
const outputPath = process.argv[3];
if (!rawPath || !outputPath) {
  throw new Error('Usage: node Summarize-TrackBCdpDetachedEdges.mjs <private-raw-snapshot> <sanitized-summary>');
}

const snapshot = JSON.parse(await fs.readFile(rawPath, 'utf8'));
const meta = snapshot.snapshot?.meta ?? {};
const nodeFields = meta.node_fields ?? [];
const edgeFields = meta.edge_fields ?? [];
const nodeTypes = meta.node_types?.[0] ?? [];
const edgeTypes = meta.edge_types?.[0] ?? [];
const nodes = snapshot.nodes ?? [];
const edges = snapshot.edges ?? [];
const nodeWidth = nodeFields.length;
const edgeWidth = edgeFields.length;
const nodeTypeIndex = nodeFields.indexOf('type');
const nodeSelfSizeIndex = nodeFields.indexOf('self_size');
const nodeEdgeCountIndex = nodeFields.indexOf('edge_count');
const nodeDetachednessIndex = nodeFields.indexOf('detachedness');
const edgeTypeIndex = edgeFields.indexOf('type');
const edgeToNodeIndex = edgeFields.indexOf('to_node');
const edgeNameIndex = edgeFields.indexOf('name_or_index');
const strings = snapshot.strings ?? [];
if (nodeWidth <= 0 || edgeWidth <= 0 || nodeTypeIndex < 0 || nodeSelfSizeIndex < 0 || nodeEdgeCountIndex < 0 || edgeTypeIndex < 0 || edgeToNodeIndex < 0) {
  throw new Error('Unsupported heap snapshot schema.');
}

const nodeCount = Math.floor(nodes.length / nodeWidth);
const nodeTypesByIndex = new Array(nodeCount);
const nodeSelfBytes = new Float64Array(nodeCount);
const nodeEdgeCounts = new Uint32Array(nodeCount);
const detached = new Set();
const detachedSelfByType = new Map();
for (let nodeIndex = 0; nodeIndex < nodeCount; nodeIndex += 1) {
  const offset = nodeIndex * nodeWidth;
  const type = String(nodeTypes[nodes[offset + nodeTypeIndex]] ?? 'unknown');
  const selfBytes = Number(nodes[offset + nodeSelfSizeIndex] ?? 0);
  const edgeCount = Number(nodes[offset + nodeEdgeCountIndex] ?? 0);
  nodeTypesByIndex[nodeIndex] = type;
  nodeSelfBytes[nodeIndex] = Number.isFinite(selfBytes) ? selfBytes : 0;
  nodeEdgeCounts[nodeIndex] = Number.isFinite(edgeCount) && edgeCount >= 0 ? edgeCount : 0;
  if (nodeDetachednessIndex >= 0 && Number(nodes[offset + nodeDetachednessIndex]) > 0) {
    detached.add(nodeIndex);
    const current = detachedSelfByType.get(type) ?? { type, count: 0, selfBytes: 0 };
    current.count += 1;
    current.selfBytes += nodeSelfBytes[nodeIndex];
    detachedSelfByType.set(type, current);
  }
}

const incomingByEdgeType = new Map();
const incomingBySourceType = new Map();
const incomingByPair = new Map();
const incomingByNameCategory = new Map();
const incomingCountByNode = new Map();
let edgeOffset = 0;
let totalEdges = 0;
for (let sourceIndex = 0; sourceIndex < nodeCount; sourceIndex += 1) {
  const sourceType = nodeTypesByIndex[sourceIndex];
  const count = nodeEdgeCounts[sourceIndex];
  for (let edgeIndex = 0; edgeIndex < count; edgeIndex += 1) {
    const current = edgeOffset + edgeIndex * edgeWidth;
    const targetArrayIndex = Number(edges[current + edgeToNodeIndex] ?? -1);
    const targetIndex = targetArrayIndex >= 0 ? Math.floor(targetArrayIndex / nodeWidth) : -1;
    totalEdges += 1;
    if (!detached.has(targetIndex)) continue;
    const edgeType = String(edgeTypes[edges[current + edgeTypeIndex]] ?? 'unknown');
    const nameValue = edgeNameIndex >= 0 ? strings[edges[current + edgeNameIndex]] : null;
    const nameText = typeof nameValue === 'string' ? nameValue.toLowerCase() : '';
    const nameCategory = edgeType === 'element'
      ? 'element-index'
      : /event|listener|handler|callback/.test(nameText)
        ? 'event-listener-like'
        : /parent|child|owner|node|document|element/.test(nameText)
          ? 'dom-relationship-like'
          : /cache|map|set|store|state|message|channel|guild/.test(nameText)
            ? 'application-state-like'
            : /context|scope|weak/.test(nameText)
              ? 'runtime-context-like'
              : nameText
                ? 'other-named-property'
                : 'unnamed-edge';
    incomingCountByNode.set(targetIndex, (incomingCountByNode.get(targetIndex) ?? 0) + 1);
    incomingByEdgeType.set(edgeType, (incomingByEdgeType.get(edgeType) ?? 0) + 1);
    incomingBySourceType.set(sourceType, (incomingBySourceType.get(sourceType) ?? 0) + 1);
    const pair = `${sourceType}|${edgeType}`;
    incomingByPair.set(pair, (incomingByPair.get(pair) ?? 0) + 1);
    incomingByNameCategory.set(nameCategory, (incomingByNameCategory.get(nameCategory) ?? 0) + 1);
  }
  edgeOffset += count * edgeWidth;
}

function rankedMap(map, keyName) {
  return [...map.entries()]
    .sort((left, right) => right[1] - left[1])
    .slice(0, 20)
    .map(([key, count]) => ({ [keyName]: key, count }));
}

const summary = {
  schemaVersion: 1,
  capturedAt: new Date().toISOString(),
  policy: 'Sanitized aggregate-only detached-edge summary. Names, strings, URLs, page text, cookies, tokens, heap objects, and raw edges are not emitted.',
  nodeCount,
  edgeCount: totalEdges,
  detachedNodeCount: detached.size,
  detachedNodesWithIncomingEdges: [...incomingCountByNode.values()].filter((count) => count > 0).length,
  detachedNodesWithNoIncomingEdges: [...detached].filter((nodeIndex) => !incomingCountByNode.has(nodeIndex)).length,
  detachedSelfByType: [...detachedSelfByType.values()]
    .sort((left, right) => right.selfBytes - left.selfBytes)
    .map((row) => ({ ...row, selfMiB: row.selfBytes / (1024 * 1024) })),
  incomingByEdgeType: rankedMap(incomingByEdgeType, 'edgeType'),
  incomingBySourceType: rankedMap(incomingBySourceType, 'sourceType'),
  incomingBySourceAndEdgeType: rankedMap(incomingByPair, 'sourceTypeAndEdgeType'),
  incomingBySanitizedNameCategory: rankedMap(incomingByNameCategory, 'nameCategory'),
};
await fs.writeFile(outputPath, JSON.stringify(summary, null, 2), 'utf8');
console.log(JSON.stringify({ outputPath, detachedNodeCount: summary.detachedNodeCount, detachedNodesWithIncomingEdges: summary.detachedNodesWithIncomingEdges }));
