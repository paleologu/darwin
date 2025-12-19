# frozen_string_literal: true

module Darwin
  module Blocks
    class AttributeHandler < BaseHandler
      def assemble_args
        return unless block.args_name.present? || block.args_type.present?

        block.args = [block.args_name, block.args_type]
      end

      def validate!
        block.errors.add(:args_name, "can't be blank") if block.args_name.blank?
        block.errors.add(:args_type, "can't be blank") if block.args_type.blank?
      end
    end
  end
end
