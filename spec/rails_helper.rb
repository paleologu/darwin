# frozen_string_literal: true

# Set the environment to test
ENV['RAILS_ENV'] ||= 'test'

# Load the Rails environment
# Load the dummy Rails application
require_relative 'dummy/config/environment'

# Load RSpec and other test dependencies
require 'rspec/rails'

# Schema maintenance will be handled in the before(:suite) block

require 'database_cleaner/active_record'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories.
Dir[File.join(__dir__, 'support/**/*.rb')].each { |f| require f }

# Configure RSpec
RSpec.configure do |config|
  config.include TestHelpers
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.use_transactional_fixtures = false

  config.before(:suite) do
    # Manually run migrations to ensure the test database is up-to-date
    migration_paths = ActiveRecord::Migrator.migrations_paths
    ActiveRecord::MigrationContext.new(migration_paths).migrate
    DatabaseCleaner.clean_with(:truncation)
  end









  config.before(:each) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end


end
