# frozen_string_literal: true

require 'servus'

module Darwin
  module BlockBuilder
    module Create
      class Service < Servus::Base
        def initialize(model:, params:)
          @model = model
          @params = params
        end

        def call
          block = @model.blocks.new(@params)
          return failure(block.errors.full_messages.to_sentence, block:) unless block.save

          touch_inverse_association(block)

          sync_models!(block)
          Darwin::Runtime.reload_all!(current_model: @model, builder: true)

          runtime_class = Darwin::Runtime.const_get(@model.name.classify)
          success(block:, model: @model, runtime_class:)
        rescue StandardError => e
          failure(e.message)
        end

        private

        def touch_inverse_association(block)
          return unless %w[has_many has_one].include?(block.method_name)

          target_class_name = block.options&.dig('class_name') || block.args.first.to_s.camelize.singularize
          target_model = Darwin::Model.find_by(name: target_class_name)
          return unless target_model

          inverse_name = @model.name.underscore
          inverse_block = target_model.blocks.find_by(method_name: 'belongs_to', args: [inverse_name])
          target_model.blocks.create!(method_name: 'belongs_to', args: [inverse_name]) unless inverse_block
        end

        def sync_models!(block) # Blocks do not create columns unless they are associations.
          models_to_sync = [@model]
          if %w[has_many has_one].include?(block.method_name)
            target_class_name = block.options&.dig('class_name') || block.args.first.to_s.camelize.singularize
            target_model = Darwin::Model.find_by(name: target_class_name)
            models_to_sync << target_model if target_model
          end
          models_to_sync.compact.uniq.each { |m| Darwin::SchemaManager.sync!(m) }
        end
      end
    end
  end
end
