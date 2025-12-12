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
          return failure(@model.errors.full_messages.to_sentence) unless @model.update(@params)

          Darwin::SchemaSyncJob.run(model_id: @model.id, action: 'sync', builder: true)

          success(model: @model)
        rescue StandardError => e
          failure(e.message)
        end
      end
    end
  end
end
