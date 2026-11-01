export class Builder {
  constructor(
    adapter,
    {
      delay = (ms) => new Promise((r) => setTimeout(r, ms)),
      onChange = () => {},
    } = {},
  ) {
    this.adapter = adapter;
    this.delay = delay;
    this.onChange = onChange;
    this.state = "idle";
    this.done = 0;
    this.total = 0;
  }
  notify(message = "") {
    this.onChange({
      state: this.state,
      done: this.done,
      total: this.total,
      message,
    });
  }
  pause() {
    if (this.state === "running") {
      this.state = "paused";
      this.notify("Пауза");
    }
  }
  resume() {
    if (this.state === "paused") {
      this.state = "running";
      this.notify("Продолжение");
      this.wake?.();
    }
  }
  cancel() {
    if (this.state === "running" || this.state === "paused") {
      this.state = "cancelling";
      this.notify("Ожидание завершения текущего шага");
      this.wake?.();
    }
  }
  async start(plan, intervalMs = 250) {
    if (["running", "paused", "cancelling"].includes(this.state))
      throw new Error("Процесс уже запущен");
    if (!Array.isArray(plan) || !plan.length) throw new Error("План пуст");
    if (!Number.isFinite(intervalMs) || intervalMs < 50 || intervalMs > 5000)
      throw new Error("Интервал должен быть от 50 до 5000 мс");
    this.done = 0;
    this.total = plan.length;
    this.state = "running";
    this.notify("Симуляция запущена");
    try {
      for (const block of plan) {
        while (this.state === "paused")
          await new Promise((resolve) => {
            this.wake = resolve;
          });
        this.wake = null;
        if (this.state === "cancelling") {
          this.state = "cancelled";
          this.notify("Отменено");
          return;
        }
        await this.adapter.place(block);
        this.done++;
        this.notify(`Блок ${this.done}/${this.total}`);
        if (this.state === "cancelling") {
          this.state = "cancelled";
          this.notify("Отменено");
          return;
        }
        if (this.done < this.total) await this.delay(intervalMs);
      }
      if (this.state === "cancelling") {
        this.state = "cancelled";
        this.notify("Отменено");
        return;
      }
      // A pause may arrive while the last asynchronous placement is in flight.
      while (this.state === "paused")
        await new Promise((resolve) => {
          this.wake = resolve;
        });
      this.wake = null;
      if (this.state === "cancelling") {
        this.state = "cancelled";
        this.notify("Отменено");
        return;
      }
      this.state = "completed";
      this.notify("Симуляция завершена");
    } catch (error) {
      this.state = "failed";
      this.notify(`Ошибка: ${error.message}`);
    }
  }
}
