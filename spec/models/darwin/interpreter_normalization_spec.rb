# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Darwin::Interpreter, type: :model do
  it 'normalizes association names so nested attributes work with inconsistent user input' do
    phone_model = Darwin::Model.create!(name: 'Phone')
    comment_model = Darwin::Model.create!(name: 'Comment')

    phone_model.blocks.create!(method_name: 'attribute', args: %w[name string])
    phone_model.blocks.create!(method_name: 'has_many', args: ['Comment'])
    phone_model.blocks.create!(method_name: 'accepts_nested_attributes_for', args: ['Comment'])

    comment_model.blocks.create!(method_name: 'belongs_to', args: ['Phone'])
    comment_model.blocks.create!(method_name: 'attribute', args: %w[body text])

    Darwin::Runtime.reload_all!(builder: true)

    phone_class = phone_model.runtime_constant

    expect(phone_class.nested_attributes_options.keys).to include(:comments)

    phone = phone_class.create!(name: 'Desk', comments_attributes: [{ body: 'hello' }])

    expect(phone.comments.size).to eq(1)
    expect(phone.comments.first.body).to eq('hello')
    expect(phone.comments.first.phone_id).to eq(phone.id)
  end
end
