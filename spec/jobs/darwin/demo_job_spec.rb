# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'

RSpec.describe Darwin::DemoJob do
  let(:path) { Rails.root.join('tmp', 'darwin_demo_job.txt') }

  it 'runs through Active Job and writes the payload' do
    FileUtils.rm_f(path)

    described_class.perform_later('hello from test')

    expect(File.read(path)).to include('hello from test')
  ensure
    FileUtils.rm_f(path)
  end
end
