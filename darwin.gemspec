# frozen_string_literal: true

require_relative 'lib/darwin/version'

Gem::Specification.new do |spec|
  spec.name          = 'darwin'
  spec.version       = Darwin::VERSION
  spec.authors       = ['Mihail Paleologu']
  spec.email         = ['mihail@botlegion.io']

  spec.summary       = 'Dynamic ActiveRecord'
  spec.description   = 'Create user-defined resource types with dynamic fields, validations, and relationships.'
  spec.homepage      = 'https://github.com/paleologu/resource'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['{app,db,lib,config,vendor}/**/*', 'MIT-LICENSE', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord'
  spec.add_dependency 'sqlite3', '~> 2.1'
  spec.add_dependency 'rails', '>= 7.0', '< 9.0'
  spec.add_dependency 'class_variants', '~> 1.1'
  spec.add_dependency 'fernandes-ui'
  spec.add_dependency 'importmap-rails', '< 3', '>= 2'
  spec.add_dependency 'turbo-rails', '< 3', '>= 2'
  spec.add_dependency 'view_component', '~> 4.1.0'
  spec.add_dependency "phlex-rails", "~> 2.0"
  #spec.add_dependency "view_component", "~> 3.0"
  spec.add_dependency 'servus'

  spec.add_development_dependency 'database_cleaner-active_record'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'capybara'
  spec.add_development_dependency 'selenium-webdriver'
  spec.add_development_dependency 'faker'
  spec.add_development_dependency 'benchmark-ips'
end
