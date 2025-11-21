# frozen_string_literal: true

require 'rails_helper'
require 'darwin/schema_manager'

RSpec.describe 'Darwin Model Lifecycle', type: :model do
  before(:each) do
    # Clean slate for each test
    Darwin::Model.destroy_all
    Darwin::SchemaManager.cleanup!
  end

  it 'correctly manages the schema throughout the model and block lifecycle' do
    # 1. Create a model
    author_model = Darwin::Model.create!(name: 'Author')
    expect(ActiveRecord::Base.connection.table_exists?('darwin_authors')).to be true

    # 2. Add an attribute block
    author_model.blocks.create!(method_name: 'attribute', args: %w[name string])
    expect(ActiveRecord::Base.connection.column_exists?('darwin_authors', :name)).to be true

    # 3. Create a second model
    article_model = Darwin::Model.create!(name: 'Article')
    expect(ActiveRecord::Base.connection.table_exists?('darwin_articles')).to be true

    # 4. Add a has_many association
    author_model.blocks.create!(method_name: 'has_many', args: ['articles'])

    # Verify inverse association was created
    article_model.reload
    belongs_to_block = article_model.blocks.find { |b| b.method_name == 'belongs_to' && b.args == ['author'] }
    expect(belongs_to_block).not_to be_nil

    # Verify foreign key was added
    expect(ActiveRecord::Base.connection.column_exists?('darwin_articles', :author_id)).to be true

    # 5. Destroy the model
    author_model.destroy
    expect(ActiveRecord::Base.connection.table_exists?('darwin_authors')).to be false
  end
end
