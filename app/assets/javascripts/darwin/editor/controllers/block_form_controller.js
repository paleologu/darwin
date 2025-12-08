import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link", "attributeSelect", "validationTypeContainer", "validationField"]
  static values = { modelName: String }

  connect() {
    if (this.hasAttributeSelectTarget) {
      this.populateValidationTypes()
    }
  }

  update(event) {
    if (!this.hasLinkTarget) return
    const blockType = event.target.value
    if (!blockType) return

    try {
      const url = new URL(this.linkTarget.href)
      url.searchParams.set("method_name", blockType)
      this.linkTarget.href = url.toString()
    } catch (_error) {
      // Fall back to the original behavior if URL parsing fails
      this.linkTarget.href = this.linkTarget.href.replace(/method_name=\w+/, `method_name=${blockType}`)
    }
  }

  populateValidationTypes() {
    const attributeName = this.attributeSelectTarget.value
    if (!attributeName) {
      this.hideValidationOptions()
      return
    }

    fetch(`/darwin/models/${this.modelNameValue}/attribute_type?attribute_name=${attributeName}`)
      .then((response) => response.json())
      .then((data) => {
        const validValidations = this.getValidationsForType(data.type)
        this.showValidationOptions(validValidations)
      })
      .catch(() => {
        this.hideValidationOptions()
      })
  }

  toggleValidationFields() {
    const selectedValidation = this.validationTypeValue()
    this.validationFieldTargets.forEach((field) => {
      if (field.dataset.validationType === selectedValidation) {
        field.style.display = "block"
      } else {
        field.style.display = "none"
      }
    })
  }

  getValidationsForType(type) {
    const validations = {
      string: ["presence", "length", "format", "uniqueness", "inclusion", "exclusion"],
      text: ["presence", "length", "uniqueness", "inclusion", "exclusion"],
      integer: ["presence", "numericality", "uniqueness", "inclusion", "exclusion"],
      float: ["presence", "numericality", "uniqueness", "inclusion", "exclusion"],
      decimal: ["presence", "numericality", "uniqueness", "inclusion", "exclusion"],
      boolean: ["inclusion", "exclusion"],
      date: ["presence"],
      datetime: ["presence"],
    }
    return validations[type] || []
  }

  showValidationOptions(validValidations) {
    if (!this.hasValidationTypeContainerTarget) return

    const container = this.validationTypeContainerTarget
    container.style.display = validValidations.length ? "block" : "none"

    const hiddenInput =
      container.querySelector('[data-ui--select-target="hiddenInput"]') || container.querySelector("select")
    const items = container.querySelectorAll('[data-ui--select-target="item"]')

    items.forEach((item) => {
      const enabled = validValidations.length === 0 || validValidations.includes(item.dataset.value)
      item.dataset.disabled = enabled ? "false" : "true"
      item.hidden = !enabled
      item.setAttribute("aria-hidden", (!enabled).toString())
    })

    if (!hiddenInput) return

    const nextValue = validValidations.includes(hiddenInput.value) ? hiddenInput.value : validValidations[0] || ""
    if (hiddenInput.value !== nextValue) {
      hiddenInput.value = nextValue
      hiddenInput.dispatchEvent(new Event("change", { bubbles: true }))
    }

    const selectController = this.uiSelectController(container)
    if (selectController && nextValue) {
      selectController.valueValue = nextValue
    }
    this.toggleValidationFields()
  }

  hideValidationOptions() {
    if (!this.hasValidationTypeContainerTarget) return
    this.validationTypeContainerTarget.style.display = "none"
    this.validationFieldTargets.forEach((field) => (field.style.display = "none"))
  }

  validationTypeValue() {
    const selectValue = this.validationTypeContainerTarget?.querySelector('[data-ui--select-target="hiddenInput"]')?.value
    if (selectValue) return selectValue

    const fallbackSelect = this.validationTypeContainerTarget?.querySelector("select")
    return fallbackSelect ? fallbackSelect.value : ""
  }

  uiSelectController(container) {
    if (!container) return null
    const selectElement = container.querySelector('[data-controller="ui--select"]')
    if (!selectElement || !this.application.getControllerForElementAndIdentifier) return null
    return this.application.getControllerForElementAndIdentifier(selectElement, "ui--select")
  }
}
