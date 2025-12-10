import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]

  connect() {
    // Ensure items have click handlers
    this.itemTargets.forEach(item => {
      item.addEventListener("click", () => this.go(item.value))
    })
  }

  go(modelName) {
    if (!modelName) return
    const url = `/v2/editor/${modelName}`
    Turbo.visit(url)
  }
}
