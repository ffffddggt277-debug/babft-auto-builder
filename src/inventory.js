export function countBlocks(blueprint) {
  const result = Object.create(null);
  for (const b of blueprint.blocks) result[b.type] = (result[b.type] ?? 0) + 1;
  return result;
}
export function compareInventory(required, available) {
  const result = [];
  for (const type of Object.keys(required).sort()) {
    const have = available[type] ?? 0;
    if (!Number.isSafeInteger(have) || have < 0)
      throw new Error(
        `Инвентарь ${type}: требуется целое неотрицательное число`,
      );
    result.push({
      type,
      required: required[type],
      available: have,
      missing: Math.max(0, required[type] - have),
    });
  }
  return result;
}
