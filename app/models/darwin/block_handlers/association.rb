# frozen_string_literal: true

module Darwin
  module BlockHandlers
    class Association < Base
      def self.association_models(block)
        Darwin::Model.where.not(id: block.darwin_model_id).pluck(:name)
      end

      def self.select_field(block, label:)
        {
          component: :select,
          name: :args_name,
          label: label,
          placeholder: 'Select model',
          value: Array(block.args).first,
          collection: association_models(block).map { |name| { value: name, label: name } },
          hidden_data: { 'ui--select-target': 'hiddenInput' },
          content_classes: 'w-full'
        }
      end
    end
  end
end
