# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Darwin::Blocks::AssociationHandler do
  let(:model) { Darwin::Model.create!(name: 'AssociationModel') }
  let(:block) { model.blocks.build(method_name: method_name) }
  let(:handler) { described_class.new(block) }

  describe '#assemble_args' do
    let(:method_name) { 'has_many' }

    it 'wraps the provided association name in an array' do
      block.args_name = 'Blog Posts'

      handler.assemble_args

      expect(block.args).to eq(['Blog Posts'])
    end

    it 'skips assembly when no name is given' do
      handler.assemble_args

      expect(block.args).to eq([])
    end
  end

  describe '#normalize_args' do
    context 'for has_many' do
      let(:method_name) { 'has_many' }

      it 'underscores and pluralizes the name' do
        block.args = ['Blog Post']

        handler.normalize_args

        expect(block.args).to eq(['blog_posts'])
      end
    end

    context 'for belongs_to' do
      let(:method_name) { 'belongs_to' }

      it 'underscores and singularizes the name' do
        block.args = ['Authors']

        handler.normalize_args

        expect(block.args).to eq(['author'])
      end
    end
  end
end
