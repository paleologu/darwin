# frozen_string_literal: true

module Darwin
  module Blocks
    class Registry
      HANDLERS = {
        'attribute' => Blocks::AttributeHandler,
        'has_many' => Blocks::AssociationHandler,
        'has_one' => Blocks::AssociationHandler,
        'belongs_to' => Blocks::AssociationHandler,
        'validates' => Blocks::ValidationHandler,
        'accepts_nested_attributes_for' => Blocks::NestedAttributesHandler
      }.freeze

      def self.handler_for(block)
        handler_class = HANDLERS[block.method_name]
        handler_class&.new(block)
      end
    end
  end
end
