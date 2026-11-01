import { parseBlueprint } from "./schema.js";
import { loadBlueprint } from "./loader.js";
import { countBlocks, compareInventory } from "./inventory.js";
import { makePlan } from "./planner.js";
import { MockGameAdapter } from "./adapters.js";
import { Builder } from "./builder.js";
import { Logger } from "./logger.js";
import { drawPreview } from "./preview.js";
const $ = (id) => document.getElementById(id);
const logger = new Logger();
let blueprint = null;
let loading = false;
const adapter = new MockGameAdapter();
const states = {
  idle: "ОЖИДАНИЕ",
  running: "РАБОТАЕТ",
  paused: "ПАУЗА",
  cancelling: "ОТМЕНА…",
  cancelled: "ОТМЕНЕНО",
  completed: "ГОТОВО",
  failed: "ОШИБКА",
};
function log(message) {
  logger.add(message);
  $("log").textContent = logger.text();
}
function status(message, error = false) {
  $("status").textContent = message;
  $("status").classList.toggle("error", error);
  log(message);
}
const builder = new Builder(adapter, {
  onChange: (s) => {
    $("state").textContent = states[s.state];
    $("progress").max = s.total || 1;
    $("progress").value = s.done;
    $("progress-label").textContent = `${s.done} / ${s.total} блоков`;
    drawPreview(
      $("canvas"),
      blueprint,
      new Set(adapter.placed.map((b) => b.index)),
    );
    if (s.message) log(s.message);
    sync();
  },
});
function busy() {
  return loading || ["running", "paused", "cancelling"].includes(builder.state);
}
function sync() {
  for (const id of [
    "url",
    "load",
    "json",
    "example",
    "validate",
    "wood",
    "order",
    "speed",
    "check-resources",
  ])
    $(id).disabled = busy();
  $("start").disabled = busy() || !blueprint;
  $("pause").disabled = !["running", "paused"].includes(builder.state);
  $("pause").textContent = builder.state === "paused" ? "Продолжить" : "Пауза";
  $("cancel").disabled = !["running", "paused"].includes(builder.state);
}
function updateResources() {
  if (!blueprint) return;
  try {
    const input = $("wood").value;
    const n = Number(input);
    if (!input || !Number.isSafeInteger(n) || n < 0 || n > 1_000_000)
      throw new Error("Введите целое число от 0 до 1000000");
    const rows = compareInventory(countBlocks(blueprint), { wood: n });
    $("resources").textContent = rows
      .map(
        (r) =>
          `${r.type}: нужно ${r.required} · есть ${r.available} · не хватает ${r.missing}`,
      )
      .join("\n");
  } catch (e) {
    $("resources").textContent = e.message;
  }
}
function updateSteps() {
  const list = $("steps-list");
  list.replaceChildren();
  if (!blueprint) return;
  for (const b of makePlan(blueprint, $("order").value)) {
    const item = document.createElement("li");
    item.textContent = `${b.type} · позиция (${b.position.x}, ${b.position.y}, ${b.position.z}) · размер (${b.size.x}, ${b.size.y}, ${b.size.z}) · поворот (${b.rotation.x}, ${b.rotation.y}, ${b.rotation.z})° · ${b.color}`;
    list.appendChild(item);
  }
}
function accept(b) {
  blueprint = b;
  adapter.reset();
  $("empty").hidden = true;
  $("block-count").textContent = `${b.blocks.length} блоков`;
  $("plan-summary").textContent =
    `${b.name}\n${b.blocks.length} шагов · последовательность: ${$("order").selectedOptions[0].textContent}`;
  $("progress").max = b.blocks.length;
  $("progress").value = 0;
  $("progress-label").textContent = `0 / ${b.blocks.length} блоков`;
  $("state").textContent = states.idle;
  drawPreview($("canvas"), b);
  updateResources();
  updateSteps();
  status("Схема проверена. План готов.");
  sync();
}
function invalidate() {
  blueprint = null;
  adapter.reset();
  $("block-count").textContent = "0 блоков";
  $("plan-summary").textContent = "План ещё не создан";
  $("resources").textContent = "После проверки здесь появится расчёт.";
  $("empty").hidden = false;
  updateSteps();
  drawPreview($("canvas"), null);
  $("state").textContent = states.idle;
  $("progress").max = 1;
  $("progress").value = 0;
  $("progress-label").textContent = "0 / 0 блоков";
  sync();
}
$("json").addEventListener("input", () => {
  invalidate();
  $("status").textContent = "Схема изменена; проверьте её заново.";
});
$("validate").addEventListener("click", () => {
  try {
    accept(parseBlueprint($("json").value));
  } catch (e) {
    invalidate();
    status(e.message, true);
  }
});
$("load").addEventListener("click", async () => {
  loading = true;
  sync();
  status("Загрузка…");
  try {
    const b = await loadBlueprint($("url").value);
    $("json").value = JSON.stringify(
      {
        version: b.version,
        name: b.name,
        blocks: b.blocks.map(({ index, ...rest }) => rest),
      },
      null,
      2,
    );
    accept(b);
  } catch (e) {
    invalidate();
    status(e.message, true);
  } finally {
    loading = false;
    sync();
  }
});
$("example").addEventListener("click", async () => {
  loading = true;
  sync();
  try {
    const res = await fetch("./examples/test_build.json");
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const text = await res.text();
    const b = parseBlueprint(text);
    $("json").value = text;
    accept(b);
  } catch (e) {
    invalidate();
    status(`Не удалось открыть пример: ${e.message}`, true);
  } finally {
    loading = false;
    sync();
  }
});
$("wood").addEventListener("input", updateResources);
$("order").addEventListener("change", () => {
  updateSteps();
  if (blueprint)
    $("plan-summary").textContent =
      `${blueprint.name}\n${blueprint.blocks.length} шагов · последовательность: ${$("order").selectedOptions[0].textContent}`;
});
$("start").addEventListener("click", async () => {
  try {
    const n = Number($("wood").value),
      ms = Number($("speed").value);
    if (!$("wood").value || !Number.isSafeInteger(n) || n < 0 || n > 1_000_000)
      throw new Error("Инвентарь: введите целое число от 0 до 1000000");
    if (!$("speed").value || !Number.isFinite(ms) || ms < 50 || ms > 5000)
      throw new Error("Интервал должен быть от 50 до 5000 мс");
    const rows = compareInventory(countBlocks(blueprint), { wood: n });
    if ($("check-resources").checked && rows.some((r) => r.missing))
      throw new Error(
        "Недостаточно ресурсов; измените инвентарь или отключите проверку",
      );
    adapter.reset();
    await builder.start(makePlan(blueprint, $("order").value), ms);
  } catch (e) {
    status(e.message, true);
  }
});
$("pause").addEventListener("click", () =>
  builder.state === "paused" ? builder.resume() : builder.pause(),
);
$("cancel").addEventListener("click", () => builder.cancel());
$("toggle").addEventListener("click", () => {
  const hidden = !$("workspace").hidden;
  $("workspace").hidden = hidden;
  $("toggle").setAttribute("aria-expanded", String(!hidden));
  $("toggle").textContent = hidden ? "Открыть панель" : "Скрыть панель";
});
$("download-log").addEventListener("click", () => {
  const a = document.createElement("a");
  const url = URL.createObjectURL(
    new Blob([logger.text()], { type: "text/plain;charset=utf-8" }),
  );
  a.href = url;
  a.download = "babft-log.txt";
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
});
sync();
