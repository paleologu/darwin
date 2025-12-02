# frozen_string_literal: true

module Darwin
  class Column
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Serializers::JSON

    attribute :name, :string
    attribute :type, :string
    attribute :default, :string
    attribute :null, :boolean, default: true
    attribute :limit, :integer
    attribute :precision, :integer
    attribute :scale, :integer

    validates :name, presence: true
    validates :type, presence: true, inclusion: { in: %w[string integer boolean text datetime date float decimal] }

    def self.dump(value)
      return [] if value.nil?

      Array(value).map do |column|
        column.respond_to?(:to_hash) ? column.to_hash : column
      end
    end

    def self.load(value)
      return [] if value.nil?

      raw_columns = value.is_a?(String) ? JSON.parse(value) : value
      Array(raw_columns).map do |column|
        column.is_a?(Darwin::Column) ? column : from_hash(column)
      end
    end

    def self.from_hash(hash)
      options = hash['options'] || hash[:options] || {}
      new(
        name: hash['name'] || hash[:name],
        type: hash['type'] || hash[:type],
        default: options['default'] || options[:default],
        null: options.key?('null') ? options['null'] : options[:null],
        limit: options['limit'] || options[:limit],
        precision: options['precision'] || options[:precision],
        scale: options['scale'] || options[:scale]
      )
    end

    def to_hash
      {
        'name' => name,
        'type' => type,
        'options' => {
          'default' => default,
          'null' => null,
          'limit' => limit,
          'precision' => precision,
          'scale' => scale
        }.compact
      }
    end
  end
end
