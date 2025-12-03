# frozen_string_literal: true

module Darwin
  module Ui
    class BannerComponent < ::ViewComponent::Base
      attr_reader :title, :body

      def initialize(title:, body: nil)
        @title = title
        @body = body
      end
    end
  end
end
