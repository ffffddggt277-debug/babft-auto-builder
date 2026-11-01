import { parseBlueprint } from "./schema.js";
export function validateRawUrl(value) {
  let url;
  try {
    url = new URL(value);
  } catch {
    throw new Error("Неверный URL");
  }
  if (
    url.protocol !== "https:" ||
    url.hostname !== "raw.githubusercontent.com" ||
    url.port ||
    url.username ||
    url.password ||
    url.search ||
    url.hash ||
    url.pathname.includes("%") ||
    url.pathname.split("/").length < 5 ||
    url.pathname
      .split("/")
      .some((x, i) => i > 0 && (!x || x === "." || x === ".."))
  )
    throw new Error(
      "Нужен публичный HTTPS GitHub Raw URL: owner/repo/ref/путь, без параметров",
    );
  return url.href;
}
export async function loadBlueprint(
  url,
  { fetchImpl = fetch, timeoutMs = 10000 } = {},
) {
  const safeUrl = validateRawUrl(url);
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  let response;
  try {
    response = await fetchImpl(safeUrl, {
      signal: controller.signal,
      redirect: "error",
      credentials: "omit",
      cache: "no-store",
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const length = Number(response.headers?.get("content-length"));
    if (length > 1_000_000) throw new Error("Ответ больше 1 МБ");
    // Abort before buffering an unbounded response, even without Content-Length.
    let text;
    if (response.body?.getReader) {
      const reader = response.body.getReader();
      const chunks = [];
      let total = 0;
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          total += value.byteLength;
          if (total > 1_000_000) {
            await reader.cancel();
            throw new Error("Ответ больше 1 МБ");
          }
          chunks.push(value);
        }
      } finally {
        reader.releaseLock();
      }
      const bytes = new Uint8Array(total);
      let offset = 0;
      for (const chunk of chunks) {
        bytes.set(chunk, offset);
        offset += chunk.byteLength;
      }
      text = new TextDecoder("utf-8", { fatal: true }).decode(bytes);
    } else {
      text = await response.text();
    }
    return parseBlueprint(text);
  } catch (error) {
    if (error.name === "AbortError")
      throw new Error("Загрузка прервана по тайм-ауту");
    throw new Error(`Загрузка или проверка не удалась: ${error.message}`);
  } finally {
    clearTimeout(timer);
  }
}
