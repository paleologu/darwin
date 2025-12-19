# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Darwin::Block, type: :model do
  let(:model) { Darwin::Model.create!(name: 'TestModel') }

  describe 'validations' do
    it 'is valid with a method_name, args_name, and args_type for an attribute' do
      block = model.blocks.new(method_name: 'attribute', args_name: 'title', args_type: 'string')
      expect(block).to be_valid
    end

    it 'is invalid without a method_name' do
      block = model.blocks.new(args_name: 'title')
      expect(block).not_to be_valid
    end

    it 'is invalid without an args_name for an attribute' do
      block = model.blocks.new(method_name: 'attribute', args_type: 'string')
      expect(block).not_to be_valid
      expect(block.errors.full_messages).to include("Args name can't be blank")
    end
  end

  describe '#options' do
    it 'stores and retrieves serialized data' do
      options = { 'validations' => { 'presence' => true } }
      block = model.blocks.create!(method_name: 'attribute', args_name: 'title', args_type: 'string', options: options)

      expect(block.reload.options).to eq(options)
    end
  end

  describe 'position defaults' do
    it 'assigns sequential positions when none are provided' do
      first_block = model.blocks.create!(method_name: 'attribute', args_name: 'first', args_type: 'string')
      second_block = model.blocks.create!(method_name: 'attribute', args_name: 'second', args_type: 'string')

      expect(first_block.position).to eq(0)
      expect(second_block.position).to eq(1)
    end
  end
end
