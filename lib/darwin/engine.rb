# frozen_string_literal: true


module Darwin
  class Engine < ::Rails::Engine
    isolate_namespace Darwin

    initializer :append_migrations do |app|
      if app.root.to_s != root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
