# frozen_string_literal: true

module Darwin
  class Model < ::ApplicationRecord
    self.table_name = 'darwin_models'

    has_many :blocks, class_name: 'Darwin::Block', foreign_key: 'model_id', dependent: :destroy,
                      inverse_of: :darwin_model

    accepts_nested_attributes_for :blocks, allow_destroy: true

    validates :name, presence: true, uniqueness: true,
                     format: { with: /\A[a-zA-Z_][a-zA-Z0-9_]*\z/, message: 'must be a valid database identifier' }

    def to_param
      name.downcase_first
    end

  end
end
