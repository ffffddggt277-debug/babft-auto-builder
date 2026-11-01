// All effects are local, reversible simulation. This does not talk to Roblox.
export class MockGameAdapter {
  constructor({ failAt = -1 } = {}) {
    this.placed = [];
    this.failAt = failAt;
  }
  async place(block) {
    if (this.placed.length === this.failAt)
      throw new Error("Тестовая ошибка адаптера");
    this.placed.push(block);
  }
  reset() {
    this.placed = [];
  }
}
export class GameAdapter {
  async place() {
    throw new Error("Интеграция с BABFT не подтверждена и отключена");
  }
  async inventory() {
    throw new Error("Чтение игрового инвентаря недоступно");
  }
}
export class EconomyAdapter {
  async balance() {
    throw new Error("Баланс золота недоступен");
  }
  async earn() {
    throw new Error("Автозаработок не реализован");
  }
  async purchase() {
    throw new Error("Автопокупка не реализована");
  }
}
