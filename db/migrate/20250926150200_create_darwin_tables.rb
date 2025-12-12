# frozen_string_literal: true

class CreateDarwinTables < ActiveRecord::Migration[7.1]
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

    create_table :darwin_blocks do |t|
      t.references :model, null: false, foreign_key: { to_table: :darwin_models }
      t.string :method_name, null: false
      t.json   :args, default: {} # Perhaps should be [] as per structure in rails. 
      t.json   :options, default: {}
      t.text   :body
      t.integer :position, default: 0
      t.timestamps
    end

  end

end
