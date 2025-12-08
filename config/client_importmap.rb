# frozen_string_literal: true

pin 'darwin-client-controllers', to: 'darwin/client/controllers/index.js'
pin_all_from File.expand_path('../app/assets/javascripts/darwin/client/controllers', __dir__),
             under: 'darwin-client-controllers',
             to: 'darwin/client/controllers'

pin 'darwin-client', to: 'darwin/client/index.js'

# Fernandez UI (components + Stimulus controllers)
pin 'ui', to: 'ui.esm.js', preload: true
ui_gem_path = Gem::Specification.find_by_name('fernandes-ui').gem_dir
pin_all_from File.expand_path('app/assets/javascripts/ui/controllers', ui_gem_path), under: 'ui/controllers'
