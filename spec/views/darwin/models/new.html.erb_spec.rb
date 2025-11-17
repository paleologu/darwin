require 'rails_helper'

RSpec.describe "darwin/models/new", type: :view do
  before(:each) do
    assign(:model, Darwin::Model.new)
  end

  it "renders new model form" do
    render

    assert_select "form[action=?][method=?]", darwin.models_path, "post" do
      assert_select "input[name=?]", "darwin_model[name]"
    end
  end
end