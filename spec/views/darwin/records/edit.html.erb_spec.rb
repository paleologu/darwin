require 'rails_helper'

RSpec.describe "darwin/records/edit", type: :view do
  helper Darwin::ModelsHelper
  let(:book_model) { Darwin::ModelBuilder::Create::Service.call(params: { name: "Book" }).data[:model] }

  before(:each) do
    Darwin::SchemaManager.sync!(book_model)
    Darwin::Runtime.reload_all!(builder: true)
    Object.const_set("Book", Darwin::Runtime.const_get("Book")) unless Object.const_defined?("Book")

    assign(:model, book_model)
    @record = assign(:record, Book.create!())
  end

  it "renders the edit record form" do
    render
    assert_select "form" do
    end
  end
end
