require 'rails_helper'

RSpec.describe "darwin/records/show", type: :view do
  let(:book_model) { Darwin::Model.create!(name: "Book") }

  before(:each) do
    ActiveRecord::Schema.define do
      create_table :books, force: true do |t|
        t.string :name
        t.timestamps
      end
    end
  end

  before(:each) do
    # Create a dummy class for Book
    unless Object.const_defined?("Book")
      Object.const_set("Book", Class.new(ApplicationRecord))
    end

    assign(:model, book_model)
    @record = assign(:record, Book.create!())
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Book/)
  end
end