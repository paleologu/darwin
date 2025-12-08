# frozen_string_literal: true

module Darwin
  module ApplicationHelper
    def darwin_editor_javascript_tags
      darwin_importmap_tags(:editor, 'darwin-editor')
    end

    def darwin_client_javascript_tags
      darwin_importmap_tags(:client, 'darwin-client')
    end

    def darwin_importmap_tags(namespace, entry_point)
      map = Darwin::Engine.importmaps[namespace]

      safe_join(
        [
          javascript_inline_importmap_tag(map.to_json(resolver: self)),
          javascript_importmap_module_preload_tags(map),
          javascript_import_module_tag(entry_point)
        ],
        "\n"
      )
    end

    def model_active?(model)
      if @model.present? && @model == model
        true
      else
        false
      end
    end
  end
end
