require 'rails_helper'

RSpec.describe "darwin/records/new", type: :view do
  let(:book_model) { Darwin::Model.create!(name: "Book") }

  before(:each) do
    ActiveRecord::Schema.define do
      create_table :books, force: true do |t|
        t.string :name
        t.timestamps
      end
    end
    # Create a dummy class for Book
    unless Object.const_defined?("Book")
      Object.const_set("Book", Class.new(ApplicationRecord))
    end

    assign(:model, book_model)
    assign(:record, Book.new)
  end

  it "renders new record form" do
    render
    assert_select "form" do
    end
  end
end