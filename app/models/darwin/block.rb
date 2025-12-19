# frozen_string_literal: true

module Darwin
  class Block < ::ApplicationRecord
    self.table_name = 'darwin_blocks'

    belongs_to :darwin_model, class_name: 'Darwin::Model', foreign_key: :model_id, touch: true

    attribute :position, :integer, default: nil
    # https://www.visuality.pl/posts/active-record---store-vs-store-accessor
    attribute :args, :json, default: []
    attribute :options, :json, default: {}

    # Virtual attributes for the 'attribute' block form
    attr_accessor :validation_type
    attr_writer :args_name, :args_type

    before_validation :assemble_args_with_handler, if: :handler
    before_validation :normalize_args_with_handler, if: :handler
    before_create :set_position

    validates :method_name, presence: true
    validate :validate_with_handler, if: :handler

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

    def assemble_args_with_handler
      handler.assemble_args
    end

    def normalize_args_with_handler
      handler.normalize_args
    end

    def validate_with_handler
      handler.validate!
    end

    def handler
      @handler ||= Darwin::Blocks::Registry.handler_for(self)
    end

    def set_position
      return unless position.nil?

      self.position = (darwin_model.blocks.maximum(:position) || -1) + 1
    end
  end

end
