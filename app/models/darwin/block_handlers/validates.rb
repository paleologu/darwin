# frozen_string_literal: true

module Darwin
  module BlockHandlers
    class Validates < Base
      VALIDATION_MATRIX = {
        presence: %w[string text integer float decimal date datetime],
        numericality: %w[integer float decimal],
        uniqueness: %w[string text integer float decimal],
        length: %w[string text],
        format: %w[string],
        inclusion: %w[string text integer float decimal boolean],
        exclusion: %w[string text integer float decimal boolean]
      }.freeze

      def self.form_attributes(block, view_context:)
        runtime_class = view_context.runtime_class_for(block.darwin_model)
        attribute_choices = (runtime_class&.columns || []).map { |c| { name: c.name, type: c.type.to_s } }

        {
          data: {
            controller: 'block-form',
            'block-form-model-name-value': block.darwin_model.to_param,
            'block-form-attribute-type-url-value': view_context.attribute_type_model_path(block.darwin_model),
            'block-form-attributes-value': attribute_choices.to_json
          },
          class: 'space-y-4'
        }
      end

      def self.form_fields(block, view_context:)
        runtime_class = view_context.runtime_class_for(block.darwin_model)
        attribute_choices = (runtime_class&.columns || []).map { |c| { name: c.name, type: c.type.to_s } }
        selected_validation = block.validation_type.presence || block.options.keys.first
        options_hash = block.options || {}

        [
          hidden_method_field(block),
          attribute_select_field(block, attribute_choices),
          validation_select_field(selected_validation),
          validation_switch_field(:presence, block, description: 'Require this field to be present.'),
          validation_switch_field(:numericality, block, description: 'Limit to numeric values.'),
          validation_switch_field(:uniqueness, block, description: 'Ensure values are unique.'),
          length_field(block, options_hash),
          format_field(block, options_hash),
          inclusion_field(block, options_hash, key: :inclusion),
          inclusion_field(block, options_hash, key: :exclusion)
        ]
      end

      def self.attribute_select_field(block, attribute_choices)
        {
          component: :select,
          name: :args_name,
          label: 'Attribute',
          placeholder: 'Pick an attribute',
          value: block.args_name,
          collection: attribute_choices.map { |attr| { value: attr[:name], label: attr[:name].humanize, data: { value: attr[:name], type: attr[:type], 'ui--select-target': 'item' } } },
          hidden_data: {
            'ui--select-target': 'hiddenInput',
            'block-form-target': 'attributeSelect',
            action: 'change->block-form#populateValidationTypes'
          },
          select_data: { action: 'ui--select:select->block-form#selectAttribute ui--select:change->block-form#selectAttribute' },
          content_classes: 'w-full'
        }
      end

      def self.validation_select_field(selected_validation)
        {
          component: :select,
          name: :validation_type,
          label: 'Validation',
          placeholder: 'Select validation',
          value: selected_validation,
          collection: VALIDATION_MATRIX.map do |validation, allowed_types|
            {
              value: validation,
              label: validation.to_s.humanize,
              data: { allowed_types: allowed_types.join(' '), value: validation, 'ui--select-target': 'item' }
            }
          end,
          hidden_data: {
            'ui--select-target': 'hiddenInput',
            action: 'change->block-form#toggleValidationFields'
          },
          select_data: { action: 'ui--select:select->block-form#selectValidation ui--select:change->block-form#selectValidation' },
          content_classes: 'w-full',
          content_attributes: { data: { 'block-form-target': 'validationTypeContainer' } }
        }
      end

      def self.validation_switch_field(key, block, description:)
        {
          component: :switch,
          scope: :options,
          name: key,
          label: key.to_s.humanize,
          checked: block.options && block.options[key.to_s],
          wrapper_attributes: {
            data: { 'block-form-target': 'validationField', validation_type: key },
            style: 'display: none;'
          },
          description: description,
          content_classes: 'flex items-center gap-3'
        }
      end

      def self.length_field(block, options_hash)
        length_opts = options_hash.fetch('length', {}) || {}
        {
          component: :input_group,
          label: 'Length',
          wrapper_attributes: {
            data: { 'block-form-target': 'validationField', validation_type: 'length' },
            style: 'display: none;'
          },
          content_classes: 'grid grid-cols-1 gap-3 sm:grid-cols-2',
          inputs: [
            {
              component: :input,
              scope: %i[options length],
              name: :minimum,
              placeholder: 'Minimum',
              type: 'number',
              value: length_opts['minimum']
            },
            {
              component: :input,
              scope: %i[options length],
              name: :maximum,
              placeholder: 'Maximum',
              type: 'number',
              value: length_opts['maximum']
            }
          ]
        }
      end

      def self.format_field(block, options_hash)
        format_opts = options_hash.fetch('format', {}) || {}
        {
          component: :input,
          scope: %i[options format],
          name: :with,
          label: 'Format',
          placeholder: 'Regex',
          value: format_opts['with'],
          wrapper_attributes: {
            data: { 'block-form-target': 'validationField', validation_type: 'format' },
            style: 'display: none;'
          }
        }
      end

      def self.inclusion_field(block, options_hash, key:)
        option_values = options_hash.fetch(key.to_s, {}) || {}
        {
          component: :input,
          scope: [:options, key],
          name: :in,
          label: key.to_s.humanize,
          placeholder: 'Comma-separated values',
          value: Array(option_values['in']).join(', '),
          wrapper_attributes: {
            data: { 'block-form-target': 'validationField', validation_type: key },
            style: 'display: none;'
          }
        }
      end
    end
  end
end
