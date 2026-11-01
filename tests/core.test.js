import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { parseBlueprint, validateBlueprint } from "../src/schema.js";
import { loadBlueprint, validateRawUrl } from "../src/loader.js";
import { countBlocks, compareInventory } from "../src/inventory.js";
import { makePlan } from "../src/planner.js";
import { Builder } from "../src/builder.js";
import {
  MockGameAdapter,
  GameAdapter,
  EconomyAdapter,
} from "../src/adapters.js";
const text = await readFile(
  new URL("../examples/test_build.json", import.meta.url),
  "utf8",
);
const valid = () => JSON.parse(text);
const url = "https://raw.githubusercontent.com/acme/repo/main/build.json";
const flush = () => new Promise((r) => setTimeout(r, 0));
test("example parses and normalizes", () => {
  const b = parseBlueprint(text);
  assert.equal(b.blocks.length, 5);
  assert.equal(b.blocks[2].index, 2);
});
test("rejects broken JSON and oversized payload", () => {
  assert.throws(() => parseBlueprint("{"), /JSON/);
  assert.throws(() => parseBlueprint(" ".repeat(1_000_001)), /1 МБ/);
});
test("requires version, name, non-empty blocks and rejects extra keys", () => {
  for (const mutate of [
    (d) => delete d.version,
    (d) => delete d.name,
    (d) => delete d.blocks,
    (d) => (d.blocks = []),
    (d) => (d.unexpected = true),
    (d) => (d.blocks[0].secret = true),
  ]) {
    const d = valid();
    mutate(d);
    assert.throws(() => validateBlueprint(d));
  }
});
test("rejects unsupported blocks", () => {
  const d = valid();
  d.blocks[0].type = "stone";
  assert.throws(() => validateBlueprint(d), /неподдерживаемый/);
});
test("validates all coordinate, size and rotation components", () => {
  for (const [key, axis, value] of [
    ["position", "x", Infinity],
    ["position", "y", 10001],
    ["position", "z", "1"],
    ["size", "x", 0],
    ["size", "y", 1001],
    ["size", "z", -1],
    ["rotation", "x", 361],
    ["rotation", "y", -361],
    ["rotation", "z", null],
  ]) {
    const d = valid();
    d.blocks[0][key][axis] = value;
    assert.throws(() => validateBlueprint(d), new RegExp(key));
  }
  const d = valid();
  delete d.blocks[0].position.x;
  assert.throws(() => validateBlueprint(d), /position.x/);
});
test("checks colors", () => {
  for (const color of ["red", "#fff", "#GG0000", null]) {
    const d = valid();
    d.blocks[0].color = color;
    assert.throws(() => validateBlueprint(d), /color/);
  }
});
test("counts and compares resources", () => {
  const b = parseBlueprint(text);
  const count = countBlocks(b);
  assert.equal(count.wood, 5);
  assert.deepEqual(compareInventory(count, { wood: 3 }), [
    { type: "wood", required: 5, available: 3, missing: 2 },
  ]);
  assert.equal(compareInventory(count, { wood: 99 })[0].missing, 0);
  assert.throws(() => compareInventory(count, { wood: -1 }));
});
test("orders deterministically without mutating original", () => {
  const b = parseBlueprint(text);
  b.blocks[0].position.y = 10;
  assert.deepEqual(
    makePlan(b, "bottom-up").map((x) => x.index),
    [1, 2, 3, 4, 0],
  );
  assert.deepEqual(
    makePlan(b, "original").map((x) => x.index),
    [0, 1, 2, 3, 4],
  );
  assert.deepEqual(
    makePlan(b, "type").map((x) => x.index),
    [0, 1, 2, 3, 4],
  );
  assert.throws(() => makePlan(b, "invalid"));
});
test("rejects URLs outside exact raw host", () => {
  assert.equal(validateRawUrl(url), url);
  for (const bad of [
    "http://raw.githubusercontent.com/a/b/c/d",
    "https://raw.githubusercontent.com.evil.test/a/b/c/d",
    "https://user@raw.githubusercontent.com/a/b/c/d",
    "https://raw.githubusercontent.com/a/b/c/d?token=x",
    "https://raw.githubusercontent.com/a/b",
    "not a URL",
  ])
    assert.throws(() => validateRawUrl(bad));
});
test("loads JSON, rejects non-200 and network errors", async () => {
  const b = await loadBlueprint(url, {
    fetchImpl: async () => new Response(text),
  });
  assert.equal(b.blocks.length, 5);
  await assert.rejects(
    loadBlueprint(url, {
      fetchImpl: async () => new Response("", { status: 404 }),
    }),
    /HTTP 404/,
  );
  await assert.rejects(
    loadBlueprint(url, {
      fetchImpl: async () => {
        throw new Error("offline");
      },
    }),
    /offline/,
  );
});
test("rejects invalid JSON from HTTP and large stream without Content-Length", async () => {
  await assert.rejects(
    loadBlueprint(url, { fetchImpl: async () => new Response("{") }),
    /JSON/,
  );
  await assert.rejects(
    loadBlueprint(url, {
      fetchImpl: async () => new Response("x".repeat(1_000_001)),
    }),
    /1 МБ/,
  );
});
test("aborts on timeout", async () => {
  const fetchImpl = (_u, { signal }) =>
    new Promise((_, reject) =>
      signal.addEventListener("abort", () =>
        reject(new DOMException("aborted", "AbortError")),
      ),
    );
  await assert.rejects(
    loadBlueprint(url, { fetchImpl, timeoutMs: 5 }),
    /тайм-аут/,
  );
});
test("simulation places all blocks in requested order", async () => {
  const b = parseBlueprint(text);
  const adapter = new MockGameAdapter();
  const builder = new Builder(adapter, { delay: async () => {} });
  await builder.start(makePlan(b), 50);
  assert.equal(builder.state, "completed");
  assert.equal(builder.done, 5);
  assert.deepEqual(
    adapter.placed.map((x) => x.index),
    [0, 1, 2, 3, 4],
  );
});
test("pause prevents the next step; resume continues", async () => {
  const plan = makePlan(parseBlueprint(text));
  let release;
  const adapter = new MockGameAdapter();
  const builder = new Builder(adapter, {
    delay: () =>
      new Promise((r) => {
        release = r;
      }),
  });
  const work = builder.start(plan, 50);
  await flush();
  builder.pause();
  release();
  await flush();
  assert.equal(adapter.placed.length, 1);
  builder.cancel();
  await work;
  assert.equal(builder.state, "cancelled");
});
test("resume after pause completes", async () => {
  const plan = makePlan(parseBlueprint(text));
  let release;
  let first = true;
  const adapter = new MockGameAdapter();
  const builder = new Builder(adapter, {
    delay: () =>
      first
        ? ((first = false),
          new Promise((r) => {
            release = r;
          }))
        : Promise.resolve(),
  });
  const work = builder.start(plan, 50);
  await flush();
  builder.pause();
  release();
  await flush();
  builder.resume();
  await work;
  assert.equal(builder.state, "completed");
});
test("cancel waits for in-flight step and prevents overlapping runs", async () => {
  let finish;
  const adapter = {
    place: () =>
      new Promise((r) => {
        finish = r;
      }),
  };
  const builder = new Builder(adapter);
  const plan = makePlan(parseBlueprint(text));
  const work = builder.start(plan, 50);
  builder.cancel();
  assert.equal(builder.state, "cancelling");
  await assert.rejects(builder.start(plan, 50), /уже запущен/);
  finish();
  await work;
  assert.equal(builder.state, "cancelled");
  assert.equal(builder.done, 1);
});
test("adapter failure ends the run and leaves a count", async () => {
  const adapter = new MockGameAdapter({ failAt: 2 });
  const builder = new Builder(adapter, { delay: async () => {} });
  await builder.start(makePlan(parseBlueprint(text)), 50);
  assert.equal(builder.state, "failed");
  assert.equal(builder.done, 2);
});
test("real game and economy adapters fail closed", async () => {
  await assert.rejects(new GameAdapter().place({}), /отключена/);
  await assert.rejects(new GameAdapter().inventory(), /недоступно/);
  await assert.rejects(new EconomyAdapter().earn(), /не реализован/);
  await assert.rejects(new EconomyAdapter().purchase(), /не реализована/);
});
