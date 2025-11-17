# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Darwin::Model, type: :model do
  before(:all) do
    setup_test_data!
  end

  after(:all) do
    clear_test_data!
  end

  let(:author) { Author.create!(name: 'Jane Doe', desc: 'Writer') }
  let(:article) { Article.create!(title: 'My Post', content: 'Hello', author: author) }

  describe 'basic CRUD operations' do
    it 'creates and retrieves an article' do
      expect(article).to be_persisted
      expect(article.title).to eq('My Post')
      expect(article.content).to eq('Hello')
    end

    it 'associates models correctly' do
      article.comments.create!(message: 'Great post!')
      expect(article.author.name).to eq('Jane Doe')
      expect(article.comments.first.message).to eq('Great post!')
    end
  end

  describe 'validations' do
    it 'validates presence of title' do
      invalid_article = Article.new(content: 'No title')
      expect(invalid_article).not_to be_valid
      expect(invalid_article.errors.full_messages).to include("Title can't be blank")
    end
  end

  describe 'nested attributes' do
    it 'creates comments through nested attributes' do
      nested_article = Article.create!(
        title: 'Nested Test',
        content: 'Nested content',
        author: author,
        comments_attributes: [{ message: 'First!' }, { message: 'Second!' }]
      )
      expect(nested_article.comments.size).to eq(2)
    end
  end

  describe 'Darwin::Model lifecycle' do
    it 'is invalid with a poorly formatted name' do
      model = Darwin::Model.new(name: 'Invalid Name')
      expect(model).not_to be_valid
      expect(model.errors.full_messages).to include('Name must be a valid database identifier')
    end

    it 'destroys dependent blocks when destroyed' do
      model = Darwin::Model.create!(name: 'TestModelForDeletion')
      model.blocks.create!(block_type: 'attribute', args_name: 'attr1', args_type: 'string')

      expect { model.destroy }.to change { Darwin::Block.count }.by(-1)
    end
  end
end
