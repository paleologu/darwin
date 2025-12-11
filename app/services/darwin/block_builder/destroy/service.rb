# frozen_string_literal: true

require 'servus'

module Darwin
  module BlockBuilder
    module Destroy
      class Service < Servus::Base
        def initialize(model:, block_id:)
          @model = model
          @block_id = block_id
        end

        def call
          block = @model.blocks.find_by(id: @block_id)
          return failure('Block not found') unless block

          models_to_sync = models_affected_by(block)

          block.destroy
          models_to_sync.each { |m| Darwin::SchemaManager.sync!(m) }
          Darwin::Runtime.reload_all!(current_model: @model, builder: true)

          runtime_class = Darwin::Runtime.const_get(@model.name.classify)
          success(model: @model, runtime_class:)
        rescue StandardError => e
          failure(e.message)
        end

        private

        def models_affected_by(block)
          models = [@model]
          if %w[has_many has_one].include?(block.method_name)
            target_class_name = block.options&.dig('class_name') || block.args.first.to_s.camelize.singularize
            target_model = Darwin::Model.find_by(name: target_class_name)
            models << target_model if target_model
          end
          models.compact.uniq
        end
      end
    end
  end
end
