# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Darwin::Blocks::AttributeHandler do
  let(:model) { Darwin::Model.create!(name: 'HandlerModel') }
  let(:block) { model.blocks.build(method_name: 'attribute') }
  let(:handler) { described_class.new(block) }

  describe '#assemble_args' do
    it 'compiles name and type into the args array' do
      block.args_name = 'Title'
      block.args_type = 'String'

      handler.assemble_args

      expect(block.args).to eq(%w[Title String])
    end

    it 'does nothing when neither value is present' do
      handler.assemble_args

      expect(block.args).to eq([])
    end
  end

  describe '#validate!' do
    it "adds an error when the attribute name is missing" do
      handler.validate!

      expect(block.errors[:args_name]).to include("can't be blank")
    end

    it 'adds an error when the attribute type is missing' do
      handler.validate!

      expect(block.errors[:args_type]).to include("can't be blank")
    end
  end
end
