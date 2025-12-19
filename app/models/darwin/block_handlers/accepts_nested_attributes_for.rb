# frozen_string_literal: true

module Darwin
  module BlockHandlers
    class AcceptsNestedAttributesFor < Base
      def self.form_fields(block, view_context:)
        runtime_class = view_context.runtime_class_for(block.darwin_model)
        associations = (runtime_class&.reflect_on_all_associations || []).map(&:name)

        [
          hidden_method_field(block),
          {
            component: :select,
            name: :args_name,
            label: 'Association',
            placeholder: 'Select association',
            value: block.args_name,
            collection: associations.map { |name| { value: name, label: name.to_s.humanize } },
            hidden_data: { 'ui--select-target': 'hiddenInput' },
            content_classes: 'w-full'
          }
        ]
      end
    end
  end
end
