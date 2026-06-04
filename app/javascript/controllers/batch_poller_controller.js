import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { batchId: Number, completed: Boolean }

  connect() {
    if (!this.completedValue) this.startPolling()
  }

  disconnect() {
    clearInterval(this.timer)
  }

  startPolling() {
    this.timer = setInterval(() => this.poll(), 3000)
  }

  async poll() {
    try {
      const res = await fetch(`/translation_batches/${this.batchIdValue}.json`)
      if (!res.ok) return
      const data = await res.json()
      if (data.completed) {
        clearInterval(this.timer)
        Turbo.visit(window.location.href)
      }
    } catch (e) {
      console.warn("Polling error:", e)
    }
  }
}
