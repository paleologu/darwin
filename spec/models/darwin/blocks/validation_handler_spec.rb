# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Darwin::Blocks::ValidationHandler do
  let(:model) { Darwin::Model.create!(name: 'ValidationModel') }
  let(:block) { model.blocks.build(method_name: 'validates') }
  let(:handler) { described_class.new(block) }

  describe '#assemble_args' do
    it 'wraps the field name in an array' do
      block.args_name = 'title'

      handler.assemble_args

      expect(block.args).to eq(['title'])
    end
  end

  describe '#normalize_args' do
    it 'keeps only the selected validation type option' do
      block.validation_type = 'presence'
      block.options = { 'presence' => true, 'length' => { 'maximum' => 50 } }

      handler.normalize_args

      expect(block.options).to eq('presence' => true)
    end

    it 'does nothing when validation type is missing' do
      block.options = { 'presence' => true }

      handler.normalize_args

      expect(block.options).to eq('presence' => true)
    end
  end

  describe '#validate!' do
    it 'requires args to be present' do
      handler.validate!

      expect(block.errors[:args]).to include("can't be blank")
    end

    it 'requires options to be present' do
      handler.validate!

      expect(block.errors[:options]).to include("can't be blank")
    end
  end
end
