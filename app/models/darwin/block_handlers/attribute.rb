# frozen_string_literal: true

module Darwin
  module BlockHandlers
    class Attribute < Base
      ATTRIBUTE_TYPES = %w[string integer boolean text datetime date float decimal].freeze

      def self.form_fields(block, view_context:)
        [
          hidden_method_field(block),
          {
            component: :input,
            name: :args_name,
            label: 'Attribute Name',
            value: block.args_name,
            error_key: :args_name
          },
          {
            component: :select,
            name: :args_type,
            label: 'Type',
            placeholder: 'Select a type',
            value: block.args_type,
            collection: ATTRIBUTE_TYPES.map { |type| { value: type, label: type.titleize } },
            hidden_data: {
              'ui--select-target': 'hiddenInput',
              block_form_target: 'attributeType',
              action: 'change->block-form#toggleAttributeFields'
            },
            error_key: :args_type,
            content_classes: 'w-full'
          },
          {
            component: :group,
            wrapper_attributes: { class: 'grid gap-4', data: { 'attribute-type': 'all' } },
            fields: [
              options_input(block, :default, label: 'Default', description: 'Optional default value for this column.'),
              options_switch(block, :null, label: 'Null', hidden_value: 0, content_classes: 'flex items-center gap-3')
            ]
          },
          {
            component: :group,
            wrapper_attributes: { class: 'grid gap-4', data: { 'attribute-type': 'string text integer binary' } },
            fields: [
              options_input(block, :limit, label: 'Limit', type: 'number')
            ]
          },
          {
            component: :group,
            wrapper_attributes: { class: 'grid gap-4', data: { 'attribute-type': 'decimal' } },
            fields: [
              options_input(block, :precision, label: 'Precision', type: 'number'),
              options_input(block, :scale, label: 'Scale', type: 'number')
            ]
          }
        ]
      end

      def self.options_input(block, key, label:, type: 'text', description: nil)
        {
          component: :input,
          scope: :options,
          name: key,
          label: label,
          type: type,
          value: block.options ? block.options[key.to_s] : nil,
          description: description
        }
      end

      def self.options_switch(block, key, label:, hidden_value: nil, content_classes: nil)
        {
          component: :switch,
          scope: :options,
          name: key,
          label: label,
          checked: block.options ? block.options[key.to_s] : false,
          hidden_value: hidden_value,
          content_classes: content_classes
        }
      end
    end
  end
end
