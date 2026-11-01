export const MAX_BLOCKS = 2000;
export const SUPPORTED = new Set(["wood"]); // Project-local identifier, not a BABFT API name.
const keysOnly = (obj, keys, where) => {
  for (const key of Object.keys(obj))
    if (!keys.includes(key))
      throw new Error(`${where}: неизвестное поле ${key}`);
};
const obj = (value, where) => {
  if (!value || typeof value !== "object" || Array.isArray(value))
    throw new Error(`${where}: требуется объект`);
  return value;
};
function vector(value, where, min, max) {
  obj(value, where);
  keysOnly(value, ["x", "y", "z"], where);
  const out = {};
  for (const k of ["x", "y", "z"]) {
    const n = value[k];
    if (typeof n !== "number" || !Number.isFinite(n) || n < min || n > max)
      throw new Error(
        `${where}.${k}: требуется конечное число от ${min} до ${max}`,
      );
    out[k] = n;
  }
  return out;
}
export function parseBlueprint(text) {
  if (
    typeof text !== "string" ||
    new TextEncoder().encode(text).length > 1_000_000
  )
    throw new Error("JSON должен быть строкой размером не более 1 МБ");
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    throw new Error("Некорректный JSON");
  }
  return validateBlueprint(data);
}
export function validateBlueprint(data) {
  obj(data, "Схема");
  keysOnly(data, ["version", "name", "blocks"], "Схема");
  if (data.version !== 1)
    throw new Error("version: поддерживается только версия 1");
  if (
    typeof data.name !== "string" ||
    !data.name.trim() ||
    data.name.length > 100
  )
    throw new Error("name: требуется непустое название до 100 символов");
  if (
    !Array.isArray(data.blocks) ||
    !data.blocks.length ||
    data.blocks.length > MAX_BLOCKS
  )
    throw new Error(`blocks: требуется массив от 1 до ${MAX_BLOCKS} блоков`);
  const blocks = data.blocks.map((raw, i) => {
    const p = `blocks[${i}]`;
    obj(raw, p);
    keysOnly(raw, ["type", "position", "size", "rotation", "color"], p);
    if (!SUPPORTED.has(raw.type))
      throw new Error(`${p}.type: неподдерживаемый блок ${String(raw.type)}`);
    const position = vector(raw.position, `${p}.position`, -10000, 10000);
    const size = vector(raw.size, `${p}.size`, 0.01, 1000);
    const rotation = vector(raw.rotation, `${p}.rotation`, -360, 360);
    if (typeof raw.color !== "string" || !/^#[0-9a-fA-F]{6}$/.test(raw.color))
      throw new Error(`${p}.color: требуется цвет #RRGGBB`);
    return {
      type: raw.type,
      position,
      size,
      rotation,
      color: raw.color.toUpperCase(),
      index: i,
    };
  });
  return { version: 1, name: data.name.trim(), blocks };
}
