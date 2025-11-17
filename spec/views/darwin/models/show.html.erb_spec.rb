require 'rails_helper'

RSpec.describe "darwin/models/show", type: :view do
  before(:each) do
    @model = assign(:model, Darwin::Model.create!(name: "Book"))
    @records = assign(:records, [])
    Darwin::Runtime.reload_all!
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Book/)
    expect(rendered).to match(/Table name:/)
  end
end