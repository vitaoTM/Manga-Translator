import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["zone", "input", "prompt", "previews"]

  dragOver(e) {
    e.preventDefault()
    this.zoneTarget.classList.add("border-violet-500", "bg-violet-500/5")
  }

  dragLeave() {
    this.zoneTarget.classList.remove("border-violet-500", "bg-violet-500/5")
  }

  drop(e) {
    e.preventDefault()
    this.zoneTarget.classList.remove("border-violet-500", "bg-violet-500/5")
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
        div.className = "border border-zinc-800 rounded overflow-hidden bg-[#0a0a1a]"
        div.innerHTML = `
          <img src="${e.target.result}" class="w-full h-24 object-cover" />
          <p class="text-[10px] text-zinc-500 p-1.5 truncate font-mono">${file.name}</p>
        `
        this.previewsTarget.appendChild(div)
      }
      reader.readAsDataURL(file)
    })
  }
}
