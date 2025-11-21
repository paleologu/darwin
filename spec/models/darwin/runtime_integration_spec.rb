# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Darwin Runtime Integration', type: :model do
  before(:each) do
    # Clear existing models and records
    Darwin::Model.destroy_all
    ActiveRecord::Base.connection.drop_table(:darwin_blocks, if_exists: true)
    ActiveRecord::Base.connection.drop_table(:darwin_models, if_exists: true)
    # Re-create the essential darwin tables
    ActiveRecord::Base.connection.create_table :darwin_models do |t|
      t.string :name
      t.string :table_name
      t.text :description
      t.timestamps
    end
    ActiveRecord::Base.connection.create_table :darwin_blocks do |t|
      t.references :model
      t.string :method_name
      t.text :args
      t.text :options
      t.text :body
      t.integer :position
      t.timestamps
    end
  end

  it 'correctly scopes models to their own tables and handles associations' do
    # 1. Create the Darwin model records
    author_model = Darwin::Model.create!(name: 'Author')
    article_model = Darwin::Model.create!(name: 'Article')
    comment_model = Darwin::Model.create!(name: 'Comment')

    # Associations
    author_model.blocks.create!(method_name: 'has_many', args: ['articles'], position: 3)
    article_model.blocks.create!(method_name: 'has_many', args: ['comments'],
                                 options: { inverse_of: 'article', dependent: :destroy }, position: 5)

    # Author
    author_model.blocks.create!(method_name: 'attribute', args: %w[name string], position: 0)
    author_model.blocks.create!(method_name: 'attribute', args: %w[desc text], position: 1)
    author_model.blocks.create!(method_name: 'validates', args: ['name'], options: { presence: true }, position: 2)

    # Article
    article_model.blocks.create!(method_name: 'attribute', args: %w[title string], position: 0)
    article_model.blocks.create!(method_name: 'attribute', args: %w[content text], position: 1)
    article_model.blocks.create!(method_name: 'validates', args: ['title'], options: { presence: true }, position: 2)
    article_model.blocks.create!(method_name: 'validates', args: ['content'], options: { length: { maximum: 500 } },
                                 position: 3)

    # Comment
    comment_model.blocks.create!(method_name: 'attribute', args: %w[message text], position: 0)
    comment_model.blocks.create!(method_name: 'validates', args: ['message'],
                                 options: { presence: true, length: { maximum: 100 } }, position: 1)

    # 2. Define classes

    Author = author_model.runtime_constant
    Article = article_model.runtime_constant
    Comment = comment_model.runtime_constant

    # 3. Create test instances
    author = Author.create!(name: 'Jane Doe', desc: 'Writer')
    article = Article.create!(title: 'My Post', content: 'Hello', author: author)
    article.comments.create!(message: 'Great post!')

    # 4. Assertions
    expect(article).to be_persisted
    expect(article.title).to eq('My Post')
    expect(article.author.name).to eq('Jane Doe')
    expect(article.comments.first.message).to eq('Great post!')

    # 5. Verification of model scoping
    expect(Comment.count).to eq(1)
    expect(Author.count).to eq(1)
    expect(Article.count).to eq(1)
    expect(Comment.all.to_a).to all(be_a(Comment))

    # 6. Dependent destroy check
    expect { article.destroy }.to change { Comment.count }.by(-1)

    # 7. Table name and runtime verification
    expect(author_model.runtime_constant.table_name).to eq('darwin_authors')
    expect(article_model.runtime_constant.table_name).to eq('darwin_articles')
    expect(comment_model.runtime_constant.table_name).to eq('darwin_comments')

    runtime_constants = Darwin::Runtime.constants.map { |c| Darwin::Runtime.const_get(c).name }.compact
    expect(runtime_constants).to include('Darwin::Runtime::Author', 'Darwin::Runtime::Article', 'Darwin::Runtime::Comment')

    db_tables = ActiveRecord::Base.connection.tables
    expect(db_tables).to include('darwin_authors', 'darwin_articles', 'darwin_comments')
  end
end
