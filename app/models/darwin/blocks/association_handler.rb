# frozen_string_literal: true

module Darwin
  module Blocks
    class AssociationHandler < BaseHandler
      def assemble_args
        return unless block.args_name.present?

        block.args = [block.args_name]
      end

      def normalize_args
        return unless block.args.present?

        raw_name = block.args.is_a?(Array) ? block.args.first : block.args
        normalized = raw_name.to_s.underscore
        normalized = normalized.pluralize if %w[has_many accepts_nested_attributes_for].include?(block.method_name)
        normalized = normalized.singularize if %w[belongs_to has_one].include?(block.method_name)

        block.args = [normalized]
      end
    end
  end
end
