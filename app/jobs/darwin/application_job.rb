# frozen_string_literal: true

module Darwin
  # Base job class for engine background workers.
  class ApplicationJob < ActiveJob::Base
    queue_as :darwin_default
  end
end
