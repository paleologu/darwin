# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Darwin asset wiring', type: :request do
  it 'renders engine-managed importmap entries for editor and client bundles' do
    get '/'

    expect(response.body).to include('darwin-editor')
    expect(response.body).to include('darwin-client')
    expect(response.body).to include('darwin/tailwind')
  end
end
