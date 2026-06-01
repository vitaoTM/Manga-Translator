import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["zone", "input", "prompt", "previews"]

  dragOver(e) {
    e.preventDefault()
    this.zoneTarget.classList.add("border-amber-400")
  }

  dragLeave() {
    this.zoneTarget.classList.remove("border-amber-400")
  }

  drop(e) {
    e.preventDefault()
    this.zoneTarget.classList.remove("border-amber-400")
    const files = e.dataTransfer.files
    if (files.length) {
      this.inputTarget.files = files
      this.showPreviews(files)
    }
  }

  preview(e) {
    this.showPreviews(e.target.files)
  }

  showPreviews(files) {
    this.promptTarget.classList.add("hidden")
    this.previewsTarget.classList.remove("hidden")
    this.previewsTarget.innerHTML = ""

    Array.from(files).forEach(file => {
      const reader = new FileReader()
      reader.onload = (e) => {
        const div = document.createElement("div")
        div.className = "border border-stone-700"
        div.innerHTML = `
          <img src="${e.target.result}" class="w-full h-24 object-cover" />
          <p class="text-xs text-stone-500 p-1 truncate">${file.name}</p>
        `
        this.previewsTarget.appendChild(div)
      }
      reader.readAsDataURL(file)
    })
  }
}
