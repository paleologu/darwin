# frozen_string_literal: true

# lib/darwin/runtime.rb
require 'darwin/block_handler_registry'

module Darwin
  module Runtime
    def self.reload_all!(current_model: nil, builder: false)
      Rails.logger.info "[Darwin::Runtime] reload_all! builder=#{builder} current_model=#{current_model&.name}"
      # Eager-load blocks to prevent N+1 queries
      models = Darwin::Model.includes(:blocks).all.to_a
      models << current_model if current_model && !models.find { |m| m.id == current_model.id }

      # Unload all existing runtime constants to ensure a clean slate.
      unload_runtime_constants!

      # Pass 1: Define all runtime classes without evaluating blocks
      define_runtime_classes(models)

      # Pass 2: Evaluate attributes for all models by priority
      blocks = models.flat_map(&:blocks)
      blocks.sort_by { |b| [block_priority(b.method_name), b.position || 0, b.id] }.each do |block|
        klass = runtime_class_for(block.darwin_model)
        Rails.logger.info "[Darwin::Runtime] evaluating block #{block.id} #{block.method_name} for #{klass.name}"
        Darwin::Interpreter.evaluate_block(klass, block, builder:)
      end
    end

    def self.unload_runtime_constants!
      Darwin::Runtime.constants.each do |const_name|
        const = Darwin::Runtime.const_get(const_name)
        Darwin::Runtime.send(:remove_const, const_name) if const.is_a?(Class) && const < ActiveRecord::Base
      end
    end

    def self.block_priority(method_name)
      Darwin::BlockHandlerRegistry.priority_for(method_name)
    end

    def self.define_runtime_classes(models)
      Rails.logger.info "[Darwin::Runtime] define_runtime_classes for #{models.map(&:name).join(', ')}"
      models.each do |model|
        klass_name = model.name.classify
        table_name = "darwin_#{model.name.to_s.tableize}"
        Darwin::SchemaManager.ensure_table!(table_name)
        klass = Class.new(::ApplicationRecord) do
          self.table_name = table_name
        end
        Darwin::Runtime.const_set(klass_name, klass)
      end
    end

    def self.runtime_class_for(model)
      Darwin::Runtime.const_get(model.name.classify)
    end
  end
end
