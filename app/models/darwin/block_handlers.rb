# frozen_string_literal: true

module Darwin
  module BlockHandlers
    HANDLERS = {
      'attribute' => 'Darwin::BlockHandlers::Attribute',
      'belongs_to' => 'Darwin::BlockHandlers::BelongsTo',
      'has_many' => 'Darwin::BlockHandlers::HasMany',
      'has_one' => 'Darwin::BlockHandlers::HasOne',
      'validates' => 'Darwin::BlockHandlers::Validates',
      'accepts_nested_attributes_for' => 'Darwin::BlockHandlers::AcceptsNestedAttributesFor'
    }.freeze

    def self.for(block)
      name = block.respond_to?(:method_name) ? block.method_name : block.to_s
      handler_constant = HANDLERS[name]
      handler_constant&.constantize
    end
  end
end
