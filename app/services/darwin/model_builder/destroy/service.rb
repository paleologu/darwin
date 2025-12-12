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
          table_name = "darwin_#{@model.name.to_s.tableize}"
          model_name = @model.name

          return failure(@model.errors.full_messages.to_sentence) unless @model.destroy

          Darwin::SchemaSyncJob.run(model_id: @model.id, action: 'drop', builder: false, model_name:, table_name:)

          success(model: @model)
        rescue StandardError => e
          failure(e.message)
        end
      end
    end
  end
end
