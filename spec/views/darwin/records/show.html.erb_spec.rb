require 'rails_helper'

RSpec.describe "darwin/records/show", type: :view do
  helper Darwin::ModelsHelper
  let(:book_model) { Darwin::ModelBuilder::Create::Service.call(params: { name: "Book" }).data[:model] }

  before(:each) do
    Darwin::SchemaManager.sync!(book_model)
    Darwin::Runtime.reload_all!(builder: true)
    Object.const_set("Book", Darwin::Runtime.const_get("Book")) unless Object.const_defined?("Book")

    assign(:model, book_model)
    assign(:runtime_class, Darwin::Runtime.const_get("Book"))
    @record = assign(:record, Book.create!())
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Book/)
  end
end
