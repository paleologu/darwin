RSpec.configure do |config|
  config.include Darwin::Engine.routes.url_helpers, type: :request
  config.include Darwin::Engine.routes.url_helpers, type: :view
end