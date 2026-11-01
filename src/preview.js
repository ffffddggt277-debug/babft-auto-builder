export function drawPreview(canvas, blueprint, highlighted = new Set()) {
  const c = canvas.getContext("2d");
  const w = canvas.width,
    h = canvas.height;
  c.clearRect(0, 0, w, h);
  if (!blueprint) return;
  const blocks = blueprint.blocks;
  let minX = Infinity,
    minZ = Infinity,
    maxX = -Infinity,
    maxZ = -Infinity;
  // Conservative rotated bounds include all yaw angles, even for non-square blocks.
  for (const b of blocks) {
    const radius = Math.hypot(b.size.x, b.size.z) / 2;
    minX = Math.min(minX, b.position.x - radius);
    maxX = Math.max(maxX, b.position.x + radius);
    minZ = Math.min(minZ, b.position.z - radius);
    maxZ = Math.max(maxZ, b.position.z + radius);
  }
  const scale = Math.min(
    (w - 90) / Math.max(maxX - minX, 1),
    (h - 90) / Math.max(maxZ - minZ, 1),
  );
  c.save();
  c.translate(w / 2, h / 2);
  c.scale(scale, scale);
  c.translate(-(minX + maxX) / 2, -(minZ + maxZ) / 2);
  const sorted = blocks
    .slice()
    .sort((a, b) => a.position.y - b.position.y || a.index - b.index);
  for (const b of sorted) {
    c.save();
    c.translate(b.position.x, b.position.z);
    c.rotate((-b.rotation.y * Math.PI) / 180);
    c.fillStyle = b.color;
    c.globalAlpha = highlighted.size && !highlighted.has(b.index) ? 0.25 : 0.9;
    c.fillRect(-b.size.x / 2, -b.size.z / 2, b.size.x, b.size.z);
    c.strokeStyle = "#3b2b20";
    c.lineWidth = Math.max(0.02, 1.5 / scale);
    c.strokeRect(-b.size.x / 2, -b.size.z / 2, b.size.x, b.size.z);
    c.restore();
  }
  c.restore();
}
