# frozen_string_literal: true

module Darwin
  module Blocks
    class ValidationHandler < BaseHandler
      def assemble_args
        return unless block.args_name.present?

        block.args = [block.args_name]
      end

      def normalize_args
        return unless block.options.is_a?(Hash) && block.validation_type.present?

        block.options = block.options.slice(block.validation_type)
      end

      def validate!
        block.errors.add(:args, "can't be blank") if block.args.blank?
        block.errors.add(:options, "can't be blank") if block.options.blank?
      end
    end
  end
end
