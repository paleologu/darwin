# frozen_string_literal: true

require 'rails_helper'
require 'benchmark'

RSpec.describe Darwin::Runtime do
  describe 'performance' do
    it 'reloads the runtime in under 200ms with 4 models' do
      # Create 4 models with attributes and associations
      user_model = Darwin::Model.create!(name: 'User')
      user_model.blocks.create!(block_type: 'attribute', args: %w[name string])

      profile_model = Darwin::Model.create!(name: 'Profile')
      profile_model.blocks.create!(block_type: 'attribute', args: %w[bio text])
      profile_model.blocks.create!(block_type: 'belongs_to', args: ['user'])

      post_model = Darwin::Model.create!(name: 'Post')
      post_model.blocks.create!(block_type: 'attribute', args: %w[title string])
      post_model.blocks.create!(block_type: 'attribute', args: %w[content text])
      post_model.blocks.create!(block_type: 'belongs_to', args: ['user'])

      comment_model = Darwin::Model.create!(name: 'Comment')
      comment_model.blocks.create!(block_type: 'attribute', args: %w[body text])
      comment_model.blocks.create!(block_type: 'belongs_to', args: ['post'])
      comment_model.blocks.create!(block_type: 'belongs_to', args: ['user'])

      # Measure the execution time of reload_all!
      time = Benchmark.measure do
        Darwin::Runtime.reload_all!
      end

      puts "Darwin::Runtime.reload_all! took #{(time.real * 1000).round(2)}ms"
      expect(time.real).to be < 0.2
    end
  end
end
