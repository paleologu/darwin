# frozen_string_literal: true

module Darwin
  module BlockHandlers
    class Base
      def self.form_fields(_block, view_context:)
        []
      end

      def self.form_attributes(_block, view_context:)
        {}
      end

      def self.hidden_method_field(block)
        {
          component: :hidden,
          name: :method_name,
          value: block.method_name
        }
      end
    end
  end
end
