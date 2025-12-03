# frozen_string_literal: true

pin 'darwin-client-controllers', to: 'darwin/client/controllers/index.js'
pin_all_from File.expand_path('../app/assets/javascripts/darwin/client/controllers', __dir__),
             under: 'darwin-client-controllers',
             to: 'darwin/client/controllers'

pin 'darwin-client', to: 'darwin/client/index.js'
