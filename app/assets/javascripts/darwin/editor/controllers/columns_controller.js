import { Controller } from "@hotwired/stimulus"

// Minimal controller to keep the column form client-side friendly.
// It normalizes the column name to snake_case and submits the form.
export default class extends Controller {
  static targets = ["nameField"]

  submit(event) {
    // If the submit was triggered by change, ensure we still POST.
    if (event.type === "change") {
      this.element.requestSubmit()
      return
    }
  }

  normalizeName() {
    if (!this.hasNameFieldTarget) return
    const raw = this.nameFieldTarget.value || ""
    const normalized = raw.trim().replace(/\s+/g, "_").replace(/[^a-zA-Z0-9_]/g, "").toString()
    this.nameFieldTarget.value = normalized
  }
}
