# frozen_string_literal: true

module Darwin
  class Model < ::ApplicationRecord
    self.table_name = 'darwin_models'

    has_many :blocks, class_name: 'Darwin::Block', foreign_key: 'model_id', dependent: :destroy,
                      inverse_of: :darwin_model

    accepts_nested_attributes_for :blocks, allow_destroy: true
    validates :name, presence: true, uniqueness: true,
                     format: { with: /\A[a-zA-Z_][a-zA-Z0-9_]*\z/, message: 'must be a valid database identifier' }

    after_commit :sync_schema_and_reload_runtime_constant, on: %i[create update]
    after_commit :drop_table_and_reload_runtime_constant, on: :destroy

    def runtime_constant
      @runtime_constant ||= define_runtime_constant
    end

    def define_runtime_constant
      klass_name = name.classify
      if Darwin::Runtime.const_defined?(klass_name, false)
        @runtime_constant = Darwin::Runtime.const_get(klass_name)
      else
        model_name = name
        table_name = "darwin_#{model_name.to_s.tableize}"
        Darwin::SchemaManager.ensure_table!(table_name)
        klass = Class.new(::ApplicationRecord) do
          self.table_name = table_name
        end
        Darwin::Runtime.const_set(klass_name, klass)
        @runtime_constant = klass
      end
    end

    def to_param
      name.downcase_first
    end

    def runtime_class 
      @runtime_class ||= begin
        models_to_load = [self] + associated_models
        models_to_load.each(&:define_runtime_constant)
        blocks_to_interpret = models_to_load.flat_map(&:blocks)
        blocks_to_interpret.sort_by { |b| Darwin::Runtime.block_priority(b.block_type) }.each do |block|
          klass = block.darwin_model.runtime_constant
          Darwin::Interpreter.evaluate_block(klass, block)
        end
        runtime_constant
      end
    end

    private

    def associated_models
      find_all_associated_models(self, Set.new)
    end

    def find_all_associated_models(model, visited)
      return [] if visited.include?(model)

      visited << model
      direct_associations = model.blocks.each_with_object([]) do |block, acc|
        next unless %w[has_many has_one belongs_to].include?(block.block_type)

        assoc_name = block.args.first
        class_name = if block.options && block.options['class_name']
                       block.options['class_name']
                     elsif block.block_type == 'has_many'
                       assoc_name.singularize.camelize
                     else
                       assoc_name.camelize
                     end
        associated_model = Darwin::Model.find_by(name: class_name)
        acc << associated_model if associated_model
      end.uniq

      (direct_associations + direct_associations.flat_map do |m|
        find_all_associated_models(m, visited)
      end).uniq
    end

    def sync_schema_and_reload_runtime_constant
      Darwin::SchemaManager.sync!(self)
      Darwin::Runtime.reload_all!(current_model: self, builder: true)
    end

    def drop_table_and_reload_runtime_constant
      Darwin::SchemaManager.drop!(self)
      Darwin::Runtime.reload_all!(builder: true)
    end
  end
end
