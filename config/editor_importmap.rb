# frozen_string_literal: true

pin 'tiptap', to: 'tiptap.bundle.js'

pin 'darwin-editor-controllers', to: 'darwin/editor/controllers/index.js'
pin_all_from File.expand_path('../app/assets/javascripts/darwin/editor/controllers', __dir__),
             under: 'darwin-editor-controllers',
             to: 'darwin/editor/controllers'

pin 'darwin-editor', to: 'darwin/editor/index.js'

# Core runtime dependencies for the editor bundle
pin '@hotwired/turbo-rails', to: '@hotwired--turbo-rails.js'
pin '@hotwired/turbo', to: '@hotwired--turbo.js'
pin '@hotwired/stimulus', to: '@hotwired--stimulus.js'
pin '@rails/request.js', to: '@rails--request.js.js'
pin 'stimulus-use'
