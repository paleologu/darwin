# frozen_string_literal: true

require 'rails_helper'
require 'darwin/schema_manager'

RSpec.describe Darwin::SchemaManager, type: :model do
  before(:each) do
    setup_test_data!
  end

  after(:each) do
    clear_test_data!
  end

  it 'drops the table when a model is destroyed' do
    model = Darwin::Model.find_by_name('Author')
    table_name = 'darwin_authors'

    expect(ActiveRecord::Base.connection.table_exists?(table_name)).to be true
    Darwin::ModelBuilder::Destroy::Service.call(model: model)
    expect(ActiveRecord::Base.connection.table_exists?(table_name)).to be false
  end

  it 'removes a column when an attribute block is destroyed' do
    model = Darwin::Model.find_by_name('Author')
    table_name = 'darwin_authors'

    expect(ActiveRecord::Base.connection.column_exists?(table_name, :name)).to be true

    attribute_block = model.blocks.where(method_name: 'attribute').find { |b| b.args == %w[name string] }
    attribute_block.destroy
    Darwin::SchemaManager.sync!(model)

    expect(ActiveRecord::Base.connection.column_exists?(table_name, :name)).to be false
  end
end

describe '.sync!' do
  it 'is idempotent and does not raise errors on subsequent calls' do
    # Create a model specifically for this test to avoid state leakage
    model = Darwin::Model.create!(name: 'TestIdempotency')
    model.blocks.create!(method_name: 'attribute', args: %w[field string])
    table_name = 'darwin_test_idempotencies'

    # First sync
    Darwin::SchemaManager.sync!(model)
    expect(ActiveRecord::Base.connection.table_exists?(table_name)).to be true
    expect(ActiveRecord::Base.connection.column_exists?(table_name, :field)).to be true

    # Capture column definitions
    columns_before = ActiveRecord::Base.connection.columns(table_name)

    # Second sync should not fail
    expect { Darwin::SchemaManager.sync!(model) }.not_to raise_error

    # Verify schema is still correct and unchanged
    expect(ActiveRecord::Base.connection.table_exists?(table_name)).to be true
    columns_after = ActiveRecord::Base.connection.columns(table_name)
    expect(columns_after.map(&:name)).to eq(columns_before.map(&:name))
    expect(columns_after.map(&:type)).to eq(columns_before.map(&:type))
  end
  it 'handles column type changes idempotently' do
    model = Darwin::Model.create!(name: 'TestTypeChange')
    model.blocks.create!(method_name: 'attribute', args: %w[field string])
    table_name = 'darwin_test_type_changes'

    # First sync: create with string type
    Darwin::SchemaManager.sync!(model)
    expect(ActiveRecord::Base.connection.columns(table_name).find { |c| c.name == 'field' }.type).to eq(:string)

    # Update the block to change the attribute type
    model.blocks.first.update!(args: %w[field integer])
    model.reload

    # Second sync: should change the column type
    Darwin::SchemaManager.sync!(model)
    column = ActiveRecord::Base.connection.columns(table_name).find { |c| c.name == 'field' }
    expect(column.type).to eq(:integer)

    # Third sync: should do nothing and not raise an error
    expect { Darwin::SchemaManager.sync!(model) }.not_to raise_error
    column_after = ActiveRecord::Base.connection.columns(table_name).find { |c| c.name == 'field' }
    expect(column_after.type).to eq(:integer)
  end

  it 'prefers metadata over attribute blocks when syncing columns' do
    model = Darwin::Model.create!(name: 'MetadataPriority')
    model.columns.create!(name: 'title', column_type: 'string', default: 'Untitled', null: false, limit: 191)
    model.blocks.create!(method_name: 'attribute', args: %w[title text])
    table_name = 'darwin_metadata_priorities'

    Darwin::SchemaManager.sync!(model)

    column = ActiveRecord::Base.connection.columns(table_name).find { |c| c.name == 'title' }
    expect(column.type).to eq(:string)
    expect(column.default).to eq('Untitled')
    expect(column.null).to be false
    expect(column.limit).to eq(191)
  end
end
