# frozen_string_literal: true

module Darwin
  module ModelBuilder
    module Create
      require 'servus'

      class Service < Servus::Base
        def initialize(params:)
          @params = params
        end

        def call
          model = Darwin::Model.new(@params)
          return failure(model.errors.full_messages.to_sentence) unless model.save

          Darwin::SchemaSyncJob.run(model_id: model.id, action: 'sync', builder: true)

          success(model:)
        rescue StandardError => e
          failure(e.message)
        end
      end
    end
  end
end
