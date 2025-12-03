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
    const blockType = event.target.value
    const newPath = this.linkTarget.href.replace(/method_name=\w+/, `method_name=${blockType}`)
    this.linkTarget.href = newPath
  }

  populateValidationTypes() {
    const attributeName = this.attributeSelectTarget.value
    if (!attributeName) {
      this.validationTypeContainerTarget.style.display = "none"
      return
    }

    fetch(`/darwin/models/${this.modelNameValue}/attribute_type?attribute_name=${attributeName}`)
      .then((response) => response.json())
      .then((data) => {
        const validationTypeSelect = this.validationTypeContainerTarget.querySelector("select")
        validationTypeSelect.innerHTML = ""

        const validValidations = this.getValidationsForType(data.type)
        validValidations.forEach((validation) => {
          const option = document.createElement("option")
          option.value = validation
          option.text = validation.charAt(0).toUpperCase() + validation.slice(1)
          validationTypeSelect.add(option)
        })

        this.validationTypeContainerTarget.style.display = "block"
        this.toggleValidationFields()
      })
  }

  toggleValidationFields() {
    const selectedValidation = this.validationTypeContainerTarget.querySelector("select").value
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
}
