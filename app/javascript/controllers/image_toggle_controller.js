import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["originalView", "translatedView", "originalBtn", "translatedBtn"]

  showOriginal() {
    this.originalViewTarget.classList.remove("hidden")
    this.translatedViewTarget.classList.add("hidden")
    this.originalBtnTarget.classList.add("border-amber-400", "text-amber-400", "bg-amber-400/10")
    this.originalBtnTarget.classList.remove("border-stone-600", "text-stone-400")
    this.translatedBtnTarget.classList.remove("border-amber-400", "text-amber-400", "bg-amber-400/10")
    this.translatedBtnTarget.classList.add("border-stone-600", "text-stone-400")
  }

  showTranslated() {
    this.translatedViewTarget.classList.remove("hidden")
    this.originalViewTarget.classList.add("hidden")
    this.translatedBtnTarget.classList.add("border-amber-400", "text-amber-400", "bg-amber-400/10")
    this.translatedBtnTarget.classList.remove("border-stone-600", "text-stone-400")
    this.originalBtnTarget.classList.remove("border-amber-400", "text-amber-400", "bg-amber-400/10")
    this.originalBtnTarget.classList.add("border-stone-600", "text-stone-400")
  }
}
