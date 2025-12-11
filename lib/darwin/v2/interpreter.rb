# frozen_string_literal: true

module Darwin
  module V2
    class Interpreter
      def self.evaluate_block(klass, block)
        case block.method_name
        when 'attribute'
          name, type = block.args
          return unless name.present? && type.present? 
          klass.attribute name.to_sym, type.to_sym

        when 'belongs_to', 'has_many', 'has_one'
          return unless block.args.first.present?
          assoc_name = block.args.first.to_sym
          return if klass.reflect_on_association(assoc_name)

          options = deep_symbolize_keys(block.options)
          options[:dependent] = options[:dependent].to_sym if options[:dependent].is_a?(String)
          options[:class_name] ||= block.args.first.to_s.camelize.singularize
          options[:foreign_key] ||= "#{assoc_name}_id"
          
          #options[:optional] = false unless options.key?(:optional) => This was for belongs_to. It's uncommenting could break something.
          
          klass.class_eval do 
            public_send(block.method_name, assoc_name, **options)
          end
          
        when 'validates'
          return unless block.args.is_a?(Array)

          validation_args = block.args.map(&:to_s).reject(&:blank?)
          validation_options = prepare_validation_options(deep_symbolize_keys(block.options))

        return if validation_args.empty? || validation_options.empty?  # Guard against blocks with no attributes to validate or no validation rules.

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
end
