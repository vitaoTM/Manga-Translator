import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["originalView", "translatedView", "originalBtn", "translatedBtn"]

  showOriginal() {
    this.originalViewTarget.classList.remove("hidden")
    this.translatedViewTarget.classList.add("hidden")
    this.originalBtnTarget.classList.add("border-violet-500", "text-violet-400", "bg-violet-500/10")
    this.originalBtnTarget.classList.remove("border-zinc-700", "text-zinc-400")
    this.translatedBtnTarget.classList.remove("border-violet-500", "text-violet-400", "bg-violet-500/10")
    this.translatedBtnTarget.classList.add("border-zinc-700", "text-zinc-400")
  }

  showTranslated() {
    this.translatedViewTarget.classList.remove("hidden")
    this.originalViewTarget.classList.add("hidden")
    this.translatedBtnTarget.classList.add("border-violet-500", "text-violet-400", "bg-violet-500/10")
    this.translatedBtnTarget.classList.remove("border-zinc-700", "text-zinc-400")
    this.originalBtnTarget.classList.remove("border-violet-500", "text-violet-400", "bg-violet-500/10")
    this.originalBtnTarget.classList.add("border-zinc-700", "text-zinc-400")
  }
}
