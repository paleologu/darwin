# frozen_string_literal: true

module Darwin
  module ModelBuilder
    module Build
      require 'servus'

      class Service < Servus::Base
        def initialize(name: nil)
          @name = name
        end

        def call
          model = @name.present? ? Darwin::Model.find_by!(name: @name.to_s.classify) : Darwin::Model.new
          success(model:)
        rescue StandardError => e
          failure(e.message)
        end
      end
    end
  end
end
