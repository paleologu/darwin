require 'rails_helper'

RSpec.describe "darwin/records/new", type: :view do
  helper Darwin::ModelsHelper
  let(:book_model) { Darwin::ModelBuilder::Create::Service.call(params: { name: "Book" }).data[:model] }

  before(:each) do
    Darwin::SchemaManager.sync!(book_model)
    Darwin::Runtime.reload_all!(builder: true)
    Object.const_set("Book", Darwin::Runtime.const_get("Book")) unless Object.const_defined?("Book")

    assign(:model, book_model)
    assign(:runtime_class, Darwin::Runtime.const_get("Book"))
    assign(:record, Book.new)
  end

  it "renders new record form" do
    render
    assert_select "form" do
    end
  end
end
