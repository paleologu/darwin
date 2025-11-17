# frozen_string_literal: true

class CreateDarwinModels < ActiveRecord::Migration[7.1]
  def change
    create_table :darwin_models do |t|
      # t.string :owner_type, null: false
      # t.bigint :owner_id, null: false
      t.string :name, null: false
      #t.string :table_name, null: false
      t.timestamps

      # t.index [:owner_type, :owner_id]
      # t.index [:owner_type, :owner_id, :name], unique: true
    end
  end
end
