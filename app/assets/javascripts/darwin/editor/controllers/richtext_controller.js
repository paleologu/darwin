import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async connect() {
    this.element.dataset.richtextLoaded = "true"

    try {
      await import("tiptap")
      this.element.dataset.richtextAvailable = "true"
    } catch (error) {
      console.warn("Darwin editor richtext: tiptap not available", error)
    }
  }
}
