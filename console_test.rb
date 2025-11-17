# frozen_string_literal: true

# console_test.rb
# This script can be run in the Rails console of a host application.
# To run it, use the following command:
# load './path/to/console_test.rb'

# Clear existing models and records
Darwin::Model.destroy_all

# ------------------------------
# 1️⃣ Create the Darwin model records
# ------------------------------
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

# ------------------------------
# 2️⃣ Define classes
# ------------------------------

Author = author_model.runtime_constant
Article = article_model.runtime_constant
Comment = comment_model.runtime_constant

# ------------------------------
# 3️⃣ Create test instances
# ------------------------------
author = Author.create!(name: 'Jane Doe', desc: 'Writer')
article = Article.create!(title: 'My Post', content: 'Hello', author: author)
article.comments.create!(message: 'Great post!')

# ------------------------------
# 4️⃣ Assertions / checks
# ------------------------------
puts '--- Running Checks ---'
puts "Article persisted: #{article.persisted?}"
puts "Article title: #{article.title}"
puts "Article content: #{article.content}"
puts "Author name: #{article.author.name}"
puts "Comment message: #{article.comments.first.message}"

# Validations
invalid_article = Article.new(content: 'No title')
puts "Invalid article valid?: #{invalid_article.valid?}"
puts "Errors: #{invalid_article.errors.full_messages}"

# Typecasting
article.title = 123
puts "Title after typecasting: #{article.title} (class: #{article.title.class})"

# Nested attributes
nested_article = Article.create!(
  title: 'Nested Test',
  content: 'Nested content',
  author: author,
  comments_attributes: [{ message: 'First!' }, { message: 'Second!' }]
)
puts "Nested comments count: #{nested_article.comments.size}"
puts '--- Checks Complete ---'
# ------------------------------
# 5️⃣ Idempotency and Dependent Destroy Checks
# ------------------------------
puts "\n--- Running Idempotency and Dependent Destroy Checks ---"

# Idempotency check
puts 'Running reload...'
Darwin::Runtime.reload_all!
count1 = Article.reflect_on_all_associations(:has_many).count { |a| a.name == :comments }
callback_count1 = Article._destroy_callbacks.count

puts 'Running reload again...'
Darwin::Runtime.reload_all!
count2 = Article.reflect_on_all_associations(:has_many).count { |a| a.name == :comments }
callback_count2 = Article._destroy_callbacks.count

puts "Association count is idempotent: #{count1 == count2}"
puts "Callback count is idempotent: #{callback_count1 == callback_count2}"

# Dependent destroy check
puts "\n--- Dependent Destroy Check ---"
article_to_destroy = Article.create!(title: 'To Be Destroyed', author: author)
article_to_destroy.comments.create!(message: 'A comment')
initial_comment_count = Comment.count
puts "Initial comment count: #{initial_comment_count}"
article_to_destroy.destroy
final_comment_count = Comment.count
puts "Final comment count: #{final_comment_count}"
puts "Comment count changed by -1: #{final_comment_count == initial_comment_count - 1}"

puts "\n--- All Checks Complete ---"
puts "\n--- Verifying Model Scoping ---"
puts 'Comment.all should only return comments.'
puts "Comment.all count: #{Comment.count}"
puts "Comment.all records: #{Comment.all.inspect}"
puts "Author.all count: #{Author.count}"
puts "Article.all count: #{Article.count}"
puts '--- Verification Complete ---'
puts "\n--- Verifying Table Names and Runtime ---"
puts "Author model table name: #{author_model.runtime_constant.table_name}"
puts "Article model table name: #{article_model.runtime_constant.table_name}"
puts "Comment model table name: #{comment_model.runtime_constant.table_name}"
puts "Darwin::Runtime constants: #{Darwin::Runtime.constants.map { |c| Darwin::Runtime.const_get(c) }.inspect}"
puts "Database tables: #{ActiveRecord::Base.connection.tables.grep(/darwin/).inspect}"
puts '--- Verification Complete ---'
puts "\n--- Verifying Runtime Cleanup ---"
Darwin::Model.destroy_all
Darwin::Runtime.reload_all!
runtime_constants = Darwin::Runtime.constants.map { |c| Darwin::Runtime.const_get(c) }
# The there shouldn't be any constants
puts "Runtime constants after destroy: #{runtime_constants.inspect}"
puts "Cleanup successful: #{runtime_constants.empty?}"
