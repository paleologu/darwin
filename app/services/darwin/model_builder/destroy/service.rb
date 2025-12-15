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

          target_table = table_name || (@model ? "darwin_#{model.name.to_s.tableize}" : nil)
          next unless target_table
          Darwin::SchemaManager.drop_table!(target_table)
          Darwin::Runtime.reload_all!(builder: false)
          
          success(model: @model)
        rescue StandardError => e
          failure(e.message)
        end
      end
    end
  end
end



