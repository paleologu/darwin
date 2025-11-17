require 'rails_helper'

RSpec.describe "darwin/models/index", type: :view do
  before(:each) do
    assign(:models, [
      Darwin::Model.create!(name: "Book"),
      Darwin::Model.create!(name: "Author")
    ])
  end

  it "renders a list of models" do
    render
    assert_select "tr>td", text: "Book", count: 1
    assert_select "tr>td", text: "Author", count: 1
  end
end