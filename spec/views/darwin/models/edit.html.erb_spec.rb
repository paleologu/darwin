require 'rails_helper'

RSpec.describe "darwin/models/edit", type: :view do
  helper Darwin::ModelsHelper
  before(:each) do
    @model = assign(:model, Darwin::Model.create!(name: "Book"))
  end

  it "renders the edit model form" do
    render

    assert_select "form[action=?][method=?]", darwin.model_path(@model), "post" do
      assert_select "input[name=?]", "model[name]"
    end
  end
end