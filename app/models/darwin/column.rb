# frozen_string_literal: true

module Darwin
  class Column < ::ApplicationRecord
    COLUMN_TYPES = %w[string integer boolean text datetime date float decimal].freeze

    belongs_to :darwin_model, class_name: 'Darwin::Model', foreign_key: 'model_id', inverse_of: :columns

    attribute :null, :boolean, default: true

    before_validation :normalize_name

    validates :name,
              presence: true,
              format: { with: /\A[a-zA-Z_][a-zA-Z0-9_]*\z/, message: 'must be a valid database identifier' },
              uniqueness: { scope: :model_id }
    validates :column_type, presence: true, inclusion: { in: COLUMN_TYPES }
    validates :limit, :precision, :scale, numericality: { allow_nil: true, only_integer: true }
    validates :null, inclusion: { in: [true, false] }

    private

    def normalize_name
      self.name = name.to_s.strip.underscore if name.present?
    end
  end
end
