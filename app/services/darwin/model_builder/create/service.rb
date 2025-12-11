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
          return failure(model.errors.full_messages.to_sentence, model:) unless model.save

          Darwin::SchemaManager.sync!(model)
          Darwin::Runtime.reload_all!(current_model: model, builder: true)

          success(model:)
        rescue StandardError => e
          failure(e.message, model: model)
        end
      end
    end
  end
end
