# frozen_string_literal: true

module Darwin
  module ModelBuilder
    module Destroy
      require 'servus'

      class Service < Servus::Base
        def initialize(model:)
          @model = model
        end

        def call
          return failure(@model.errors.full_messages.to_sentence) unless @model.destroy

          Darwin::SchemaManager.drop!(@model)
          Darwin::Runtime.reload_all!(builder: true)

          success(model: @model)
        rescue StandardError => e
          failure(e.message)
        end
      end
    end
  end
end
