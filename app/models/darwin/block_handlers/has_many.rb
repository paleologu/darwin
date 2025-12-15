# frozen_string_literal: true

module Darwin
  module BlockHandlers
    class HasMany < Association
      def self.form_fields(block, view_context:)
        [
          hidden_method_field(block),
          select_field(block, label: 'Has Many')
        ]
      end
    end
  end
end
