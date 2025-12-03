import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { highlight: String }

  connect() {
    this.element.dataset.domController = "connected"
    if (this.hasHighlightValue) {
      this.element.dataset.highlight = this.highlightValue
    }
    // eslint-disable-next-line no-console
    console.log("Darwin client dom controller connected")
  }

  toggle() {
    this.element.hidden = !this.element.hidden
  }
}
