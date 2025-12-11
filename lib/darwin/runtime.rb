# frozen_string_literal: true

# lib/darwin/runtime.rb
module Darwin
  module Runtime
    def self.reload_all!(current_model: nil, builder: false)
      # Eager-load blocks to prevent N+1 queries
      models = Darwin::Model.includes(:blocks).all.to_a
      models << current_model if current_model && !models.find { |m| m.id == current_model.id }

      # Unload all existing runtime constants to ensure a clean slate.
      unload_runtime_constants!

      # Pass 1: Define all runtime classes without evaluating blocks
      models.each(&:define_runtime_constant)

      # Pass 2: Evaluate attributes for all models by priority
      blocks = models.flat_map(&:blocks)
      blocks.sort_by { |b| block_priority(b.method_name) }.each do |block|
        klass = block.darwin_model.runtime_constant
        Darwin::Interpreter.evaluate_block(klass, block, builder:)
      end
    end


    def self.interpret_all!(current_model: nil)
      # Eager-load blocks to prevent N+1 queries
      models = Darwin::Model.includes(:blocks).all.to_a
      models << current_model if current_model && !models.find { |m| m.id == current_model.id }

      # Unload all existing runtime constants to ensure a clean slate.
      unload_runtime_constants!

      # Pass 1: Define all runtime classes without evaluating blocks
      models.each do |model|
          klass_name = model.name.classify
      if Darwin::Runtime.const_defined?(klass_name, false)
        runtime_constant = Darwin::Runtime.const_get(klass_name)
      else
        model_name = model.name
        table_name = "darwin_#{model_name.to_s.tableize}"
        klass = Class.new(::ApplicationRecord) do
          self.table_name = table_name
        end
        Darwin::Runtime.const_set(klass_name, klass)
      end
    end



      # Pass 2: Evaluate attributes for all models by priority
      blocks = models.flat_map(&:blocks)
      blocks.sort_by { |b| block_priority(b.method_name) }.each do |block|
        klass = block.darwin_model.runtime_constant
        Darwin::V2::Interpreter.evaluate_block(klass, block)
      end
    end


    def self.unload_runtime_constants!
      Darwin::Runtime.constants.each do |const_name|
        const = Darwin::Runtime.const_get(const_name)
        Darwin::Runtime.send(:remove_const, const_name) if const.is_a?(Class) && const < ActiveRecord::Base
      end
    end

    def self.block_priority(method_name)
      @priority_map ||= {
        'attribute' => 0,
        'association' => 1,
        'attachment' => 2,
        'validates' => 3,
        'accepts_nested_attributes_for' => 4,
        'callback' => 5,
        'scope' => 6
      }
      case method_name
      when 'has_many', 'has_one', 'belongs_to'
        @priority_map['association']
      when 'has_one_attached', 'has_many_attached'
        @priority_map['attachment']
      else
        @priority_map[method_name] || 99
      end
    end
  end
end
