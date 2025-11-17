# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Darwin::Model, type: :model do
  describe 'dependent destroy behavior' do
    before(:each) do
      setup_test_data!
    end

    after(:each) do
      clear_test_data!
    end

    it 'destroys dependent comments when an article is destroyed' do
      author = Author.create!(name: 'Jane Doe')
      article = Article.create!(title: 'Post', author: author)
      article.comments.create!(message: 'Test')
      expect { article.destroy }.to change { Comment.count }.by(-1)
    end

    it 'does not duplicate has_many :comments on repeated reloads' do
      Darwin::Runtime.reload_all!
      count1 = Article.reflect_on_all_associations(:has_many).count { |a| a.name == :comments }
      Darwin::Runtime.reload_all!
      count2 = Article.reflect_on_all_associations(:has_many).count { |a| a.name == :comments }
      expect(count2).to eq(count1)
    end

    it 'registers only one dependent destroy callback' do
      Darwin::Runtime.reload_all!
      destroys = Article._destroy_callbacks.count
      Darwin::Runtime.reload_all!
      expect(Article._destroy_callbacks.count).to eq(destroys)
    end

    it 'destroys only its own comments' do
      author = Author.first || Author.create!(name: 'Jane Doe')
      a1 = Article.create!(title: 'A1', author: author)
      a2 = Article.create!(title: 'A2', author: author)
      a1.comments.create!(message: 'for a1')
      c2 = a2.comments.create!(message: 'for a2')

      expect { a1.destroy }.to change { Comment.count }.by(-1)
      expect(Comment.exists?(c2.id)).to be true
    end
  end
end
