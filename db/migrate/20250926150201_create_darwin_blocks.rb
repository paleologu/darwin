# frozen_string_literal: true

class CreateDarwinBlocks < ActiveRecord::Migration[7.1]
  def change
    create_table :darwin_blocks do |t|
      t.references :model, null: false, foreign_key: { to_table: :darwin_models }
      t.string :method_name, null: false
      t.jsonb  :args, default: {}
      t.jsonb  :options, default: {}
      t.text   :body
      t.integer :position, default: 0
      t.timestamps
    end
  end
end
