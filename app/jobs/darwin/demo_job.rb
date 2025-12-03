# frozen_string_literal: true

require 'fileutils'

module Darwin
  # Simple job used to verify Active Job wiring inside the engine.
  class DemoJob < ApplicationJob
    def perform(message = 'ping')
      path = Rails.root.join('tmp', 'darwin_demo_job.txt')
      FileUtils.mkdir_p(path.dirname)
      File.write(path, "#{message}\n")
      Rails.logger.info("[Darwin::DemoJob] wrote '#{message}' to #{path}")
    end
  end
end
