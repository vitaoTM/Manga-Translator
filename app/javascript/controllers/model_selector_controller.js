import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel", "providerInput", "modelSelect", "customField"]

  selectProvider(e) {
    const selected = e.currentTarget.dataset.provider

    this.tabTargets.forEach(tab => {
      const active = tab.dataset.provider === selected
      tab.classList.toggle("bg-violet-600",  active)
      tab.classList.toggle("text-white",     active)
      tab.classList.toggle("shadow-inner",   active)
      tab.classList.toggle("text-zinc-500",  !active)
    })

    this.panelTargets.forEach(panel => {
      const active = panel.dataset.provider === selected
      panel.classList.toggle("hidden", !active)

      const input = panel.querySelector("[data-model-selector-target='providerInput']")
      if (input) input.disabled = !active

      const select = panel.querySelector("select[name='model_name']")
      if (select) select.disabled = !active
    })
  }

  toggleCustom(e) {
    const isCustom = e.target.value === "custom"
    this.customFieldTargets.forEach(f => f.classList.toggle("hidden", !isCustom))
  }
}
