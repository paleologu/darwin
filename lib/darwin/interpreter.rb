# frozen_string_literal: true

module Darwin
  class Interpreter
    def self.evaluate_block(klass, block)
      case block.block_type
      when 'attribute'
        name, type = block.args
        return unless name.present? && type.present?

        Darwin::SchemaManager.ensure_column!(klass.table_name, name, type)
        klass.reset_column_information
        klass.attribute name.to_sym, type.to_sym

      when 'belongs_to'
        return unless block.args.first.present?
        assoc_name = block.args.first.to_sym
        return if klass.reflect_on_association(assoc_name)

        options = deep_symbolize_keys(block.options)
        options[:dependent] = options[:dependent].to_sym if options[:dependent].is_a?(String)
        options[:class_name] ||= assoc_name.to_s.camelize
        options[:foreign_key] ||= "#{assoc_name}_id"
        options[:optional] = false unless options.key?(:optional)

        Darwin::SchemaManager.ensure_column!(klass.table_name, options[:foreign_key].to_s, :integer)
        klass.reset_column_information
        klass.belongs_to assoc_name, **options

      when 'has_one'
        return unless block.args.first.present?
        assoc_name = block.args.first.to_sym
        return if klass.reflect_on_association(assoc_name)

        options = deep_symbolize_keys(block.options)
        options[:class_name] ||= assoc_name.to_s.camelize
        options[:foreign_key] ||= "#{klass.name.demodulize.underscore}_id"
        options[:dependent] = options[:dependent].to_sym if options[:dependent].is_a?(String)

        target_class_name = options[:class_name]
        target_model = Darwin::Model.find_by_name(target_class_name)
        return unless target_model

        unless target_model.blocks.any? do |b|
          b.block_type == 'belongs_to' && b.args.first == klass.name.demodulize.underscore
        end
          target_model.blocks.create!(block_type: 'belongs_to', args: [klass.name.demodulize.underscore])
        end

        target_class = Darwin::Runtime.const_get(target_class_name)
        Darwin::SchemaManager.ensure_column!(target_class.table_name, options[:foreign_key].to_s, :integer)
        target_class.reset_column_information
        klass.has_one assoc_name, **options
      when 'has_many'
        return unless block.args.first.present?
        assoc_name = block.args.first.to_sym
        return if klass.reflect_on_association(assoc_name)

        options = deep_symbolize_keys(block.options)
        options[:class_name] ||= assoc_name.to_s.singularize.camelize
        options[:foreign_key] ||= "#{klass.name.demodulize.underscore}_id"

        # The dependent option must be a symbol, but gets stored as a string.
        options[:dependent] = options[:dependent].to_sym if options[:dependent].is_a?(String)

        target_class_name = options[:class_name]
        target_model = Darwin::Model.find_by_name(target_class_name)

        return unless target_model

        unless target_model.blocks.any? do |b|
          b.block_type == 'belongs_to' && b.args.first == klass.name.demodulize.underscore
        end
          target_model.blocks.create!(block_type: 'belongs_to', args: [klass.name.demodulize.underscore])
        end

        target_class = Darwin::Runtime.const_get(target_class_name)
        Darwin::SchemaManager.ensure_column!(target_class.table_name, options[:foreign_key].to_s, :integer)
        target_class.reset_column_information
        klass.has_many assoc_name, **options

      when 'validates'
        # This is the definitive fix. It makes the interpreter completely
        # resilient to malformed validation blocks.
        return unless block.args.is_a?(Array)

        validation_args = block.args.map(&:to_s).reject(&:blank?)
        validation_options = prepare_validation_options(deep_symbolize_keys(block.options))

        # Guard against blocks with no attributes to validate or no validation rules.
        return if validation_args.empty? || validation_options.empty?

        klass.validates(*validation_args.map(&:to_sym), **validation_options)
      when 'accepts_nested_attributes_for'
        return unless block.args.is_a?(Array)
        klass.accepts_nested_attributes_for(*block.args.compact.map(&:to_sym))
      end
    end

    def self.deep_symbolize_keys(hash)
      return {} unless hash.is_a?(Hash)

      hash.each_with_object({}) do |(k, v), h|
        h[k.to_sym] = v.is_a?(Hash) ? deep_symbolize_keys(v) : v
      end
    end

    def self.prepare_validation_options(opts)
      opts.transform_values do |v|
        if v.is_a?(Hash)
          prepare_validation_options(v)
        elsif v.to_s.match?(/\A\d+\z/)
          v.to_i
        else
          v
        end
      end
    end
  end
end
