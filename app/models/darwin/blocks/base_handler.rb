# frozen_string_literal: true

module Darwin
  module Blocks
    class BaseHandler
      attr_reader :block

      def initialize(block)
        @block = block
      end

      def assemble_args; end

      def normalize_args; end

      def validate!; end
    end
  end
end
