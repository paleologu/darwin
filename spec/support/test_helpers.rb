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
    author_model.blocks.create!(method_name: 'has_many', args: ['articles'], position: 3)
    article_model.blocks.create!(method_name: 'belongs_to', args: ['author'], position: 4)
    article_model.blocks.create!(method_name: 'has_many', args: ['comments'],
                                 options: { inverse_of: 'article', dependent: :destroy }, position: 5)
    comment_model.blocks.create!(method_name: 'belongs_to', args: ['article'], position: 6)

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
    article_model.blocks.create!(method_name: 'accepts_nested_attributes_for', args: ['comments'], options: {},
                                 position: 12)

    # Comment
    comment_model.blocks.create!(method_name: 'attribute', args: %w[message text], position: 0)
    comment_model.blocks.create!(method_name: 'validates', args: ['message'],
                                 options: { presence: true, length: { maximum: 100 } }, position: 1)

    Darwin::Runtime.reload_all!(builder: true)

    %i[Author Article Comment].each do |const|
      Object.send(:remove_const, const) if Object.const_defined?(const)
      Object.const_set(const, Darwin::Runtime.const_get(const))
    end
  end

  def clear_test_data!
    Darwin::Model.destroy_all
    # Undefine classes if they exist
    %i[Author Article Comment].each do |const|
      Object.send(:remove_const, const) if Object.const_defined?(const)
    end
  end
end
