export class Logger {
  constructor(limit = 200) {
    this.limit = limit;
    this.entries = [];
  }
  add(message) {
    this.entries.push(`${new Date().toISOString()} ${message}`);
    if (this.entries.length > this.limit) this.entries.shift();
  }
  text() {
    return this.entries.join("\n");
  }
}
