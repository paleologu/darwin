# frozen_string_literal: true

require 'turbo-rails'
require 'importmap-rails'
require 'class_variants'
require 'fernandes-ui'
require 'view_component'

module Darwin
  class Engine < ::Rails::Engine
    isolate_namespace Darwin

    def self.importmaps
      @importmaps ||= {
        editor: ::Importmap::Map.new,
        client: ::Importmap::Map.new
      }
    end

    initializer :append_migrations do |app|
      if app.root.to_s != root.to_s
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    initializer 'darwin.assets' do |app|
      app.config.assets.paths << Engine.root.join('app/assets/builds')
      app.config.assets.paths << Engine.root.join('app/components')
      app.config.assets.paths << Engine.root.join('app/assets/javascripts')
      app.config.assets.paths << Engine.root.join('vendor/javascript')

      app.config.assets.precompile += %w[darwin_manifest]
    end

    initializer 'darwin.helpers' do
      ActiveSupport.on_load(:action_controller_base) do
        helper Darwin::ApplicationHelper if defined?(Darwin::ApplicationHelper)
      end
    end

    initializer 'darwin.importmap', after: 'importmap' do |app|
      Engine.importmaps[:editor].draw(Engine.root.join('config/editor_importmap.rb'))
      Engine.importmaps[:client].draw(Engine.root.join('config/client_importmap.rb'))

      if (Rails.env.development? || Rails.env.test?) && !app.config.cache_classes
        Engine.importmaps[:editor].cache_sweeper(watches: [
                                                   Engine.root.join('app/assets/javascripts/darwin/editor'),
                                                   Engine.root.join('app/components')
                                                 ])

        Engine.importmaps[:client].cache_sweeper(watches: [
                                                   Engine.root.join('app/assets/javascripts/darwin/client')
                                                 ])

        ActiveSupport.on_load(:action_controller_base) do
          before_action { Engine.importmaps[:editor].cache_sweeper.execute_if_updated }
          before_action { Engine.importmaps[:client].cache_sweeper.execute_if_updated }
        end
      end
    end

    initializer 'darwin.fernandes_ui.view_paths' do
      ui_views = Pathname.new(Gem::Specification.find_by_name('fernandes-ui').gem_dir).join('app/views')

      ActiveSupport.on_load(:action_controller_base) do
        prepend_view_path ui_views
      end

      ActiveSupport.on_load(:action_mailer) do
        prepend_view_path ui_views
      end

      # RSpec view specs rely on ActionController::Base.view_paths; update it directly
      ActionController::Base.prepend_view_path(ui_views) if defined?(ActionController::Base)
    end
  end
end
