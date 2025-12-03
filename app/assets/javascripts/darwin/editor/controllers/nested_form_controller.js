import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["links", "template", "target"]

  connect() {
    // eslint-disable-next-line no-console
    console.log("Darwin editor nested-form controller connected")
  }

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.targetTarget.insertAdjacentHTML("beforeend", content)
    // eslint-disable-next-line no-console
    console.log("Darwin editor nested-form add")
  }

  remove(event) {
    event.preventDefault()
    const wrapper = event.target.closest(".nested-fields")
    if (wrapper.dataset.newRecord === "true") {
      wrapper.remove()
    } else {
      wrapper.style.display = "none"
      wrapper.querySelector("input[name*='_destroy']").value = "1"
    }
    // eslint-disable-next-line no-console
    console.log("Darwin editor nested-form remove")
  }
}
