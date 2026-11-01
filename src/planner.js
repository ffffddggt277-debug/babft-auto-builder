export function makePlan(blueprint, order = "original") {
  if (!["original", "bottom-up", "type"].includes(order))
    throw new Error("Неизвестный порядок");
  const items = blueprint.blocks.slice();
  if (order === "bottom-up")
    items.sort((a, b) => a.position.y - b.position.y || a.index - b.index);
  if (order === "type")
    items.sort((a, b) => a.type.localeCompare(b.type) || a.index - b.index);
  return items;
}
