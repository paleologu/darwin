# frozen_string_literal: true

module Darwin
  module BlockHandlers
    class BelongsTo < Association
      def self.form_fields(block, view_context:)
        [
          hidden_method_field(block),
          select_field(block, label: 'Belongs to')
        ]
      end
    end
  end
end
