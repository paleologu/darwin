import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link", "attributeSelect", "validationTypeContainer", "validationField"]
  static values = { modelName: String, attributeTypeUrl: String, attributes: Array }

  connect() {
    if (this.hasAttributeSelectTarget) {
      this.populateValidationTypes()
    }
    this.toggleValidationFields()
    this.setupObservers()
    this.ensureDefaults()
  }

  disconnect() {
    this.teardownObservers()
  }

  setupObservers() {
    this.observers = []
    if (this.hasAttributeSelectTarget) {
      this.observeValueChange(this.attributeSelectTarget, () => this.populateValidationTypes())
    }
    const validationInput =
      this.validationTypeContainerTarget?.querySelector('[data-ui--select-target=\"hiddenInput\"]') ||
      this.validationTypeContainerTarget?.querySelector('input,select')
    if (validationInput) {
      this.observeValueChange(validationInput, () => this.toggleValidationFields())
    }
  }

  teardownObservers() {
    if (!this.observers) return
    this.observers.forEach((o) => o.disconnect())
    this.observers = []
  }

  observeValueChange(element, callback) {
    const observer = new MutationObserver(callback)
    observer.observe(element, { attributes: true, attributeFilter: ['value'] })
    this.observers.push(observer)
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

  selectAttribute(event) {
    const value = this.extractSelectValue(event)
    if (!value) return
    this.setHiddenInput(this.attributeSelectTarget, value)
    this.populateValidationTypes({ detail: { value } })
  }

  selectValidation(event) {
    const value = this.extractSelectValue(event)
    if (!value) return
    const hiddenInput =
      this.validationTypeContainerTarget?.querySelector('[data-ui--select-target="hiddenInput"]') ||
      this.validationTypeContainerTarget?.querySelector("select")
    this.setHiddenInput(hiddenInput, value)
    this.toggleValidationFields({ detail: { value } })
  }

  extractSelectValue(event) {
    if (event?.detail?.value) return event.detail.value
    const item =
      event?.target?.closest?.('[data-ui--select-target="item"], [role="option"]') ||
      this.validationTypeContainerTarget?.querySelector('[data-ui--select-target="item"][data-highlighted]')
    if (!item) return null
    return (
      item.dataset.value ||
      item.getAttribute("data-value") ||
      item.getAttribute("value") ||
      (item.textContent || "").trim().toLowerCase()
    )
  }

  setHiddenInput(input, value) {
    if (!input) return
    if (input.value === value) return
    input.value = value
    input.dispatchEvent(new Event("change", { bubbles: true }))

    const container = input.closest('[data-controller="ui--select"]') || this.element
    const controller = this.uiSelectController(container)
    if (controller && controller.valueValue !== value) {
      controller.valueValue = value
    }
  }

  ensureDefaults() {
    // Preselect the first attribute if nothing is chosen, mirroring the v2 static examples behavior.
    if (this.hasAttributeSelectTarget && !this.attributeSelectTarget.value && (this.attributesValue || []).length > 0) {
      const firstAttr = this.attributesValue[0]
      if (firstAttr?.name) {
        this.setHiddenInput(this.attributeSelectTarget, firstAttr.name)
        this.populateValidationTypes({ detail: { value: firstAttr.name } })
      }
    }
  }

  populateValidationTypes(event) {
    const selectContainer = this.attributeSelectTarget?.closest('[data-controller="ui--select"]')
    const selectController = this.uiSelectController(selectContainer)
    const eventValue = event?.detail?.value

    let attributeName =
      eventValue ||
      this.attributeSelectTarget?.value ||
      selectController?.valueValue ||
      selectContainer?.querySelector('[data-ui--select-target="item"][data-highlighted]')?.dataset?.value ||
      selectContainer?.querySelector('[role="option"][aria-selected="true"]')?.dataset?.value

    if (attributeName && this.hasAttributeSelectTarget) {
      this.attributeSelectTarget.value = attributeName
    }

    if (!attributeName) {
      this.hideValidationOptions()
      return
    }

    const preloaded = (this.attributesValue || []).find((attr) => attr.name === attributeName)
    if (preloaded && preloaded.type) {
      const validValidations = this.getValidationsForType(preloaded.type)
      this.showValidationOptions(validValidations)
      return
    }

    const baseUrl =
      this.hasAttributeTypeUrlValue && this.attributeTypeUrlValue
        ? this.attributeTypeUrlValue
        : `/darwin/models/${this.modelNameValue}/attribute_type`

    fetch(`${baseUrl}?attribute_name=${attributeName}`)
      .then((response) => response.json())
      .then((data) => {
        const validValidations = this.getValidationsForType(data.type)
        this.showValidationOptions(validValidations)
      })
      .catch(() => {
        this.hideValidationOptions()
      })
  }

  toggleValidationFields(event) {
    const eventValue = event?.detail?.value
    if (eventValue && this.hasValidationTypeContainerTarget) {
      const hiddenInput = this.validationTypeContainerTarget.querySelector('[data-ui--select-target="hiddenInput"]')
      if (hiddenInput && hiddenInput.value !== eventValue) {
        hiddenInput.value = eventValue
        hiddenInput.dispatchEvent(new Event("change", { bubbles: true }))
      }
    }

    const selectedValidation = eventValue || this.validationTypeValue()
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
    const items = Array.from(
      container.querySelectorAll('[data-ui--select-target="item"], [role="option"][data-allowed-types]')
    )
    const availableValues = []

    items.forEach((item) => {
      const itemValue =
        item.dataset.value ||
        item.getAttribute("data-value") ||
        item.getAttribute("value") ||
        (item.textContent || "").trim().toLowerCase()
      const enabled = validValidations.length === 0 || validValidations.includes(itemValue)
      item.dataset.disabled = enabled ? "false" : "true"
      item.hidden = !enabled
      item.setAttribute("aria-hidden", (!enabled).toString())
      item.setAttribute("aria-disabled", (!enabled).toString())
      if (enabled && itemValue) availableValues.push(itemValue)
    })

    if (!hiddenInput) return

    const nextValue = availableValues.includes(hiddenInput.value) ? hiddenInput.value : availableValues[0] || ""
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
    if (fallbackSelect?.value) return fallbackSelect.value

    const selectController = this.uiSelectController(this.validationTypeContainerTarget)
    if (selectController?.valueValue) return selectController.valueValue

    const highlighted =
      this.validationTypeContainerTarget?.querySelector('[data-ui--select-target="item"][data-highlighted]') ||
      this.validationTypeContainerTarget?.querySelector('[role="option"][aria-selected="true"]')
    if (highlighted) {
      return (
        highlighted.dataset.value ||
        highlighted.getAttribute("data-value") ||
        highlighted.getAttribute("value") ||
        (highlighted.textContent || "").trim().toLowerCase()
      )
    }

    return ""
  }

  uiSelectController(container) {
    if (!container) return null
    const selectElement = container.querySelector('[data-controller="ui--select"]')
    if (!selectElement || !this.application.getControllerForElementAndIdentifier) return null
    return this.application.getControllerForElementAndIdentifier(selectElement, "ui--select")
  }
}
