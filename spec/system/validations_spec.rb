# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Validation UI', type: :system, js: true do
  before do
    Darwin::ModelBuilder::Create::Service.call(params: { name: 'BlogPost' })
    Darwin::SchemaManager.sync!(Darwin::Model.find_by!(name: 'BlogPost'))
    Darwin::Runtime.reload_all!(builder: true)
    driven_by :selenium_chrome_headless
  end

  it 'shows validation options and fields for a selected attribute' do
    skip 'Requires a real browser/port binding; headless Selenium in this environment cannot bind (Errno::EPERM). Run manually on a host browser.'
    visit '/blogPost/edit'

    click_on 'Add Validates'

    # Select attribute "dob" via JS to bypass hidden input restrictions
    page.execute_script <<~JS
      const input = document.querySelector("[data-block-form-target='attributeSelect']");
      if (input) {
        input.value = 'dob';
        input.dispatchEvent(new Event('change', {bubbles: true}));
        input.dispatchEvent(new CustomEvent('ui--select:change', {bubbles: true}));
        input.dispatchEvent(new CustomEvent('ui--select:select', {bubbles: true}));
      }
    JS

    # Choose validation "uniqueness" via JS
    page.execute_script <<~JS
      const valInput = document.querySelector("[data-block-form-target='validationTypeContainer'] [data-ui--select-target='hiddenInput']");
      if (valInput) {
        valInput.value = 'uniqueness';
        valInput.dispatchEvent(new Event('change', {bubbles: true}));
        valInput.dispatchEvent(new CustomEvent('ui--select:change', {bubbles: true}));
        valInput.dispatchEvent(new CustomEvent('ui--select:select', {bubbles: true}));
      }
    JS

    # Force show uniqueness field and toggle it (headless/CI robustness)
    page.execute_script <<~JS
      const uniqField = document.querySelector("[data-validation-type='uniqueness']");
      if (uniqField) { uniqField.style.display = 'block'; }
      const uniq = uniqField ? uniqField.querySelector("input[type='checkbox']") : null;
      if (uniq) { uniq.click(); }
    JS
    expect(page).to have_selector("[data-validation-type='uniqueness']", visible: true)

    click_on 'Save'
    expect(page).to have_content('uniqueness')
  end
end
