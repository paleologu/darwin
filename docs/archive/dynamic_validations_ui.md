# Dynamic Validation UI Plan

This document outlines the plan to create a dynamic user interface for adding validations to Darwin models. The goal is to only show validation rules that are relevant to the data type of the selected attribute, which will improve the user experience and reduce the likelihood of errors.

## 1. Data Type to Validation Mapping

The first step is to define which validation rules apply to which data types. This mapping will be the foundation of our dynamic UI.

| Data Type | Applicable Validations |
| :--- | :--- |
| `string` | `presence`, `length`, `format`, `uniqueness`, `inclusion`, `exclusion` |
| `text` | `presence`, `length`, `uniqueness`, `inclusion`, `exclusion` |
| `integer` | `presence`, `numericality`, `uniqueness`, `inclusion`, `exclusion` |
| `float` | `presence`, `numericality`, `uniqueness`, `inclusion`, `exclusion` |
| `decimal` | `presence`, `numericality`, `uniqueness`, `inclusion`, `exclusion` |
| `boolean` | `inclusion`, `exclusion` |
| `date` | `presence` |
| `datetime` | `presence` |

## 2. View Modifications (`_validates.html.erb`)

The `_validates.html.erb` partial will be updated to include all possible validation fields. Each field will be wrapped in a `div` with a `data` attribute that specifies which data types it's compatible with.

**Example:**

```erb
<!-- Field for 'presence' validation (compatible with most types) -->
<div data-validation-type="string text integer float decimal date datetime">
  <%= f.label :options_presence, "Presence" %>
  <%= f.check_box :options_presence %>
</div>

<!-- Field for 'numericality' validation (only for numeric types) -->
<div data-validation-type="integer float decimal" style="display: none;">
  <%= f.label :options_numericality, "Numericality" %>
  <%= f.check_box :options_numericality %>
</div>
```

## 3. Stimulus Controller (`block_form_controller.js`)

A new Stimulus controller will be created to manage the dynamic behavior of the form. This controller will be responsible for showing and hiding the validation fields based on the selected attribute.

## 4. JavaScript Logic

The Stimulus controller will have a `toggleValidationFields` action that is triggered when the user selects an attribute from the dropdown. This action will:

1.  Get the data type of the selected attribute. This will require an AJAX call to a new controller action that can look up the attribute's type.
2.  Iterate through all the validation fields in the form.
3.  Show the fields whose `data-validation-type` attribute includes the selected data type.
4.  Hide all other validation fields.

## 5. Implementation Steps

1.  **Create the Stimulus controller:** `app/javascript/controllers/block_form_controller.js`.
2.  **Update the `_validates.html.erb` partial:** Add the `data` attributes and hide the fields by default.
3.  **Add a new route and controller action:** To fetch the data type of a selected attribute.
4.  **Implement the JavaScript logic:** In the Stimulus controller to show/hide the fields.

This plan will result in a much more intuitive and user-friendly interface for managing validations in Darwin.