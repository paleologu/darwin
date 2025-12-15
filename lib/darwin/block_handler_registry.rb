# frozen_string_literal: true

module Darwin
  module BlockHandlerRegistry
    Handler = Struct.new(
      :names,
      :priority,
      :touches_schema,
      :schema_columns_proc,
      :ui_hint,
      :ui_availability_proc,
      keyword_init: true
    ) do
      def handles?(method_name)
        names.include?(method_name)
      end

      def primary_name
        names.first
      end

      def available_for_ui?(model:, runtime_class:)
        return false if ui_availability_proc && !ui_availability_proc.call(model:, runtime_class:)

        true
      end

      def schema_columns(block, model)
        return {} unless schema_columns_proc

        schema_columns_proc.call(block, model) || {}
      end
    end

    def self.handlers
      @handlers ||= [
        Handler.new(
          names: %w[attribute],
          priority: 0,
          touches_schema: :self,
          schema_columns_proc: lambda { |block, _model|
            name, type = Array(block.args)
            next {} if name.blank? || type.blank?

            {
              name.to_s => { type: type.to_sym, options: {} }
            }
          },
          ui_hint: 'Adds a typed column on this model',
          ui_availability_proc: ->(**) { true }
        ),
        Handler.new(
          names: %w[belongs_to],
          priority: 1,
          touches_schema: :self,
          schema_columns_proc: lambda { |block, _model|
            assoc_name = block.args.first.to_s.underscore
            next {} if assoc_name.blank?

            options = Darwin::Interpreter.deep_symbolize_keys(block.options) || {}
            foreign_key = options[:foreign_key] || "#{assoc_name}_id"

            {
              foreign_key => { type: :integer, options: { null: options.fetch(:optional, true) } }
            }
          },
          ui_hint: 'Adds a foreign key column on this model',
          ui_availability_proc: ->(**) { Darwin::Model.count > 1 }
        ),
        Handler.new(
          names: %w[has_many],
          priority: 1,
          touches_schema: :target,
          ui_hint: 'Creates a collection association on another model',
          ui_availability_proc: ->(**) { Darwin::Model.count > 1 }
        ),
        Handler.new(
          names: %w[has_one],
          priority: 1,
          touches_schema: :target,
          ui_hint: 'Creates a singular association on another model',
          ui_availability_proc: ->(**) { Darwin::Model.count > 1 }
        ),
        Handler.new(
          names: %w[has_one_attached],
          priority: 2,
          touches_schema: :attachment,
          ui_hint: 'Attach a single file to this model',
          ui_availability_proc: ->(**) { false }
        ),
        Handler.new(
          names: %w[has_many_attached],
          priority: 2,
          touches_schema: :attachment,
          ui_hint: 'Attach multiple files to this model',
          ui_availability_proc: ->(**) { false }
        ),
        Handler.new(
          names: %w[validates],
          priority: 3,
          touches_schema: false,
          ui_hint: 'Validate existing attributes',
          ui_availability_proc: ->(runtime_class:, **) { runtime_class&.attribute_names&.present? }
        ),
        Handler.new(
          names: %w[accepts_nested_attributes_for],
          priority: 4,
          touches_schema: false,
          ui_hint: 'Allow nested attributes for associations',
          ui_availability_proc: lambda { |runtime_class:, **|
            runtime_class&.reflect_on_all_associations&.any?
          }
        ),
        Handler.new(
          names: %w[callback],
          priority: 5,
          touches_schema: false,
          ui_hint: 'Run a callback on lifecycle events',
          ui_availability_proc: ->(**) { false }
        ),
        Handler.new(
          names: %w[scope],
          priority: 6,
          touches_schema: false,
          ui_hint: 'Define a scope on this model',
          ui_availability_proc: ->(**) { false }
        )
      ]
    end

    def self.handler_for(method_name)
      handlers.find { |handler| handler.handles?(method_name) }
    end

    def self.priority_for(method_name)
      handler_for(method_name)&.priority || 99
    end

    def self.ui_handlers(model:, runtime_class:)
      handlers.select { |handler| handler.available_for_ui?(model:, runtime_class:) }
    end

    def self.schema_columns_for(model)
      model.blocks.each_with_object({}) do |block, specs|
        handler = handler_for(block.method_name)
        next unless handler

        handler.schema_columns(block, model).each do |name, spec|
          specs[name] ||= spec
        end
      end
    end
  end
end
