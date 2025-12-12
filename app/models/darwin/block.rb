# frozen_string_literal: true

module Darwin
  class Block < ::ApplicationRecord
    self.table_name = 'darwin_blocks'

    belongs_to :darwin_model, class_name: 'Darwin::Model', foreign_key: :model_id, touch: true


    # https://www.visuality.pl/posts/active-record---store-vs-store-accessor
    attribute :args, :json, default: []
    attribute :options, :json, default: {}

    # Virtual attributes for the 'attribute' block form
    attr_accessor :validation_type
    attr_writer :args_name, :args_type

    before_validation :assemble_args, if: lambda {
      %w[has_many belongs_to has_one validates accepts_nested_attributes_for].include?(method_name)
    }
    before_validation :normalize_association_args, if: lambda {
      %w[has_many belongs_to has_one accepts_nested_attributes_for].include?(method_name)
    }
    before_validation :clean_options, if: -> { method_name == 'validates' }
    before_create :set_position

    validates :method_name, presence: true
    validate :validate_attribute_block, if: -> { method_name == 'attribute' }
    validate :validate_validation_block, if: -> { method_name == 'validates' }

    def args=(value)
      if value.is_a?(String) && !value.blank?
        begin
          super(JSON.parse(value))
        rescue JSON::ParserError
          super(value)
        end
      else
        super(value)
      end
    end

    def options=(value)
      if value.is_a?(String) && !value.blank?
        begin
          super(JSON.parse(value))
        rescue JSON::ParserError
          super(value)
        end
      else
        super(value)
      end
    end

    # Custom reader for args_name to pull from `args` array if not set by form
    def args_name
      @args_name || (args&.first if %w[attribute has_many belongs_to has_one validates
       accepts_nested_attributes_for].include?(method_name) && args.is_a?(Array))
    end

    # Custom reader for args_type to pull from `args` array if not set by form
    def args_type
      @args_type || (args&.second if method_name == 'attribute' && args.is_a?(Array))
    end

    private

    def assemble_args
      case method_name
      when 'attribute'
        self.args = [@args_name, @args_type] if @args_name.present? || @args_type.present?
      when 'has_many', 'belongs_to', 'has_one', 'validates', 'accepts_nested_attributes_for'
        self.args = [@args_name] if @args_name.present?
      end
    end

    def normalize_association_args
      return unless args.present?

      raw_name = args.is_a?(Array) ? args.first : args
      normalized = raw_name.to_s.underscore
      normalized = normalized.pluralize if method_name == 'has_many' || method_name == 'accepts_nested_attributes_for'
      normalized = normalized.singularize if method_name == 'belongs_to' || method_name == 'has_one'

      self.args = [normalized]
    end

    def validate_attribute_block
      # Use the custom readers which will have the correct values
      errors.add(:args_name, "can't be blank") if args_name.blank?
      errors.add(:args_type, "can't be blank") if args_type.blank?
    end

    def validate_validation_block
      errors.add(:args, "can't be blank") if args.empty?
      errors.add(:options, "can't be blank") if options.empty?
    end

    def clean_options
      return unless options.is_a?(Hash) && validation_type.present?

      self.options = options.slice(validation_type)
    end

    def set_position
      return unless position.blank?

      self.position = (darwin_model.blocks.maximum(:position) || 0) + 1
    end
  end

end
