import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.dataset.bannerController = "connected"
    // helps verify Stimulus wiring in dev
    // eslint-disable-next-line no-console
    console.log("Darwin editor banner controller connected")
    this.expanded = true
  }

  toggle() {
    // eslint-disable-next-line no-console
    console.log("Darwin editor banner toggle")
    this.expanded = !this.expanded
    this.element.classList.toggle("is-hidden", !this.expanded)
    // we intentionally avoid aria-hidden here to prevent hiding focused descendants
  }
}
