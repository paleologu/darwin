require 'rails_helper'

RSpec.describe "darwin/blocks/new", type: :view do
  helper Darwin::ModelsHelper
  let(:book_model) { Darwin::Model.create!(name: "Book") }

  before(:each) do
    assign(:model, book_model)
    assign(:block, Darwin::Block.new(method_name: 'attribute'))
  end

  it "renders new block form" do
    # render
    # assert_select "form[action=?][method=?]", darwin.model_blocks_path(book_model), "post" do
    # end
  end
end