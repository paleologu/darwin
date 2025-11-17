# frozen_string_literal: true

require 'rails_helper'
require 'darwin/schema_manager'

RSpec.describe 'Darwin Model creation and destruction', type: :model do
  it 'creates and removes the table and runtime constant during its lifecycle' do
    model_name = 'BlogPost'
    table_name = 'darwin_blog_posts'

    # 1. Verify initial state
    expect(ActiveRecord::Base.connection.table_exists?(table_name)).to be false
    expect(Darwin::Runtime.const_defined?(model_name)).to be false

    # 2. Create the model and verify state
    blog_post_model = Darwin::Model.create!(name: model_name)
    expect(ActiveRecord::Base.connection.table_exists?(table_name)).to be true
    expect(Darwin::Runtime.const_defined?(model_name)).to be true

    # 3. Destroy the model and verify state
    blog_post_model.destroy
    expect(ActiveRecord::Base.connection.table_exists?(table_name)).to be false
    expect(Darwin::Runtime.const_defined?(model_name)).to be false
  end
end
