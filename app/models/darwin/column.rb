# frozen_string_literal: true

module Darwin
  class Column < ::ApplicationRecord


    validates :name, presence: true
    validates :type, presence: true, inclusion: { in: %w[string integer boolean text datetime date float decimal] }


  end
end
