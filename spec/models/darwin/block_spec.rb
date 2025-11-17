# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Darwin::Block, type: :model do
  let(:model) { Darwin::Model.create!(name: 'TestModel') }

  describe 'validations' do
    it 'is valid with a block_type, args_name, and args_type for an attribute' do
      block = model.blocks.new(block_type: 'attribute', args_name: 'title', args_type: 'string')
      expect(block).to be_valid
    end

    it 'is invalid without a block_type' do
      block = model.blocks.new(args_name: 'title')
      expect(block).not_to be_valid
    end

    it 'is invalid without an args_name for an attribute' do
      block = model.blocks.new(block_type: 'attribute', args_type: 'string')
      expect(block).not_to be_valid
      expect(block.errors.full_messages).to include("Args name can't be blank")
    end
  end

  describe '#options' do
    it 'stores and retrieves serialized data' do
      options = { 'validations' => { 'presence' => true } }
      block = model.blocks.create!(block_type: 'attribute', args_name: 'title', args_type: 'string', options: options)

      expect(block.reload.options).to eq(options)
    end
  end
end
