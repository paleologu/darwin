# frozen_string_literal: true

# Set the environment to test
ENV['RAILS_ENV'] ||= 'test'

# Load the Rails environment
require 'rails'

# Ensure assets config exists for the dummy app (Rails 8 drops sprockets by default)
if defined?(Rails::Application::Configuration) && !Rails::Application::Configuration.method_defined?(:assets)
  class Rails::Application::Configuration
    class SpecAssets < ActiveSupport::OrderedOptions
      def initialize
        super
        self.paths ||= []
        self.precompile ||= []
      end
    end

    def assets
      @assets ||= SpecAssets.new
    end

    def assets=(value)
      @assets = value
    end
  end
end

require_relative 'dummy/config/environment'

# Load RSpec and other test dependencies
require 'rspec/rails'
require 'capybara/rspec'
Capybara.run_server = false
Capybara.app_host = 'http://localhost:3000'
Capybara.default_driver = :selenium_chrome_headless
Capybara.javascript_driver = :selenium_chrome_headless

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
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end

  config.before(:suite) do
    # Manually run migrations to ensure the test database is up-to-date.
    # Include engine migrations so the darwin_models table has the columns field.
    migration_paths = ActiveRecord::Migrator.migrations_paths.map { |p| File.expand_path(p, Rails.root) }
    migration_paths << Rails.root.join('db', 'migrate').to_s
    migration_paths << File.expand_path('../../db/migrate', __dir__) # engine migrations
    migration_paths.uniq!
    ActiveRecord::MigrationContext.new(migration_paths).migrate
    # Drop any leftover runtime tables from previous runs.
    connection = ActiveRecord::Base.connection
    keep_tables = %w[darwin_models darwin_blocks darwin_columns schema_migrations ar_internal_metadata]
    unless connection.table_exists?(:darwin_columns)
      connection.create_table(:darwin_columns) do |t|
        t.references :model, null: false, foreign_key: { to_table: :darwin_models }
        t.string :name, null: false
        t.string :column_type
        t.string :default
        t.boolean :null, default: true
        t.integer :limit
        t.integer :precision
        t.integer :scale
        t.timestamps
      end
      connection.add_foreign_key "darwin_columns", "darwin_models", column: "model_id" unless connection.foreign_keys('darwin_columns').any? { |fk| fk.to_table == 'darwin_models' }
      connection.reset!
    end
    connection.tables.grep(/^darwin_/).each do |table|
      next if keep_tables.include?(table)
      connection.drop_table(table, if_exists: true)
    end
    connection.reset!
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
