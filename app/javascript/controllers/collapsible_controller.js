import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["body", "icon"]

  toggle() {
    const open = !this.bodyTarget.classList.contains("hidden")
    this.bodyTarget.classList.toggle("hidden", open)
    this.iconTarget.style.transform = open ? "" : "rotate(90deg)"
  }
}
