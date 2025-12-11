# frozen_string_literal: true

module Darwin
  module ModelBuilder
    module Update
      require 'servus'

      class Service < Servus::Base
        def initialize(model:, params:)
          @model = model
          @params = params
        end

        def call
          return failure(@model.errors.full_messages.to_sentence, model: @model) unless @model.update(@params)

          Darwin::SchemaManager.sync!(@model)
          Darwin::Runtime.reload_all!(current_model: @model, builder: true)

          success(model: @model)
        rescue StandardError => e
          failure(e.message, model: @model)
        end
      end
    end
  end
end
