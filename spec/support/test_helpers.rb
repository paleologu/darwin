# frozen_string_literal: true

module TestHelpers
  def setup_test_data!
    # Clear existing models and records

    # Darwin::Model.destroy_all

    # ActiveRecord::Base.connection.tables.grep(/^darwin_(authors|articles|comments)$/).each do |table|
    #   ActiveRecord::Base.connection.drop_table(table, if_exists: true)
    # end

    # ------------------------------
    # 1️⃣ Create the Darwin model records
    author_model = Darwin::Model.create!(name: 'Author')
    article_model = Darwin::Model.create!(name: 'Article')
    comment_model = Darwin::Model.create!(name: 'Comment')

    # Associations
    author_model.blocks.create!(block_type: 'has_many', args: ['articles'], position: 3)
    article_model.blocks.create!(block_type: 'has_many', args: ['comments'],
                                 options: { inverse_of: 'article', dependent: :destroy }, position: 5)

    # Author
    author_model.blocks.create!(block_type: 'attribute', args: %w[name string], position: 0)
    author_model.blocks.create!(block_type: 'attribute', args: %w[desc text], position: 1)
    author_model.blocks.create!(block_type: 'validates', args: ['name'], options: { presence: true }, position: 2)

    # Article
    article_model.blocks.create!(block_type: 'attribute', args: %w[title string], position: 0)
    article_model.blocks.create!(block_type: 'attribute', args: %w[content text], position: 1)
    article_model.blocks.create!(block_type: 'validates', args: ['title'], options: { presence: true }, position: 2)
    article_model.blocks.create!(block_type: 'validates', args: ['content'], options: { length: { maximum: 500 } },
                                 position: 3)
    article_model.blocks.create!(block_type: 'accepts_nested_attributes_for', args: ['comments'], options: {},
                                 position: 12)

    # Comment
    comment_model.blocks.create!(block_type: 'attribute', args: %w[message text], position: 0)
    comment_model.blocks.create!(block_type: 'validates', args: ['message'],
                                 options: { presence: true, length: { maximum: 100 } }, position: 1)

    # Undefine classes if they exist
    %i[Author Article Comment].each do |const|
      Object.send(:remove_const, const) if Object.const_defined?(const)
    end

    Object.const_set('Author', author_model.runtime_constant)
    Object.const_set('Article', article_model.runtime_constant)
    Object.const_set('Comment', comment_model.runtime_constant)
  end

  def clear_test_data!
    Darwin::Model.destroy_all
    # Undefine classes if they exist
    %i[Author Article Comment].each do |const|
      Object.send(:remove_const, const) if Object.const_defined?(const)
    end
  end
end
