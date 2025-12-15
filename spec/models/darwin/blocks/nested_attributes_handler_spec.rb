# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Darwin::Blocks::NestedAttributesHandler do
  let(:model) { Darwin::Model.create!(name: 'NestedModel') }
  let(:block) { model.blocks.build(method_name: 'accepts_nested_attributes_for') }
  let(:handler) { described_class.new(block) }

  describe '#normalize_args' do
    it 'underscores and pluralizes nested attribute names' do
      block.args = ['Line Item']

      handler.normalize_args

      expect(block.args).to eq(['line_items'])
    end
  end
end
