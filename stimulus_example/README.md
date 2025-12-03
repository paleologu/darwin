# How Maglev Core Engine Integrates with Modern Rails Stack

Let me break down exactly how this Rails engine orchestrates components, views, Stimulus, Turbo, importmap, and the host app. Here's your complete implementation guide:

## 1. **Engine Foundation & Dependencies**

The engine is set up as an isolated namespace Rails engine that bundles modern Rails dependencies: [1](#0-0) 

Key dependencies in the gemspec: [2](#0-1) 

## 2. **Dual Importmap Architecture**

This is crucial: **The engine maintains TWO separate importmaps** - one for the editor interface and one for the client (preview): [3](#0-2) 

These importmaps are initialized and watched for changes: [4](#0-3) 

## 3. **Asset Pipeline Configuration**

The engine adds multiple asset paths including components directory: [5](#0-4) 

## 4. **JavaScript Loading via Helper Methods**

The engine provides custom helpers that generate importmap tags: [6](#0-5) 

These are used in layouts: [7](#0-6) 

## 5. **Stimulus Controller Architecture**

### Entry Point Structure

The editor JavaScript starts with this entry point: [8](#0-7) 

### Stimulus Application Setup

Create a Stimulus application instance: [9](#0-8) 

### Controller Registration Pattern

Controllers are explicitly registered with identifiers: [10](#0-9) 

### Co-located Component Controllers

**Key Pattern**: Stimulus controllers live alongside their ViewComponents: [11](#0-10) 

## 6. **ViewComponent Architecture**

### Base Component Pattern

Components extend ViewComponent::Base and use a view_context pattern: [12](#0-11) 

### Example Component with No Template

Some components render directly in Ruby (like IconComponent): [13](#0-12) 

### Section and Page Components

The page component orchestrates section rendering: [14](#0-13) 

Section components render ERB templates from the theme: [15](#0-14) 

## 7. **Host App Integration**

### Theme Layout in Host App

The host app creates a theme layout that uses helper methods: [16](#0-15) 

### Helper Method for Rendering Sections

The main rendering helper creates PageComponent instances: [17](#0-16) 

### Section Template Pattern

Section templates in the host app access settings and blocks: [18](#0-17) 

## 8. **Turbo Integration**

Turbo is imported at the top level and configured with event listeners: [19](#0-18) 

The layout uses Turbo features like turbo_frame_tag: [20](#0-19) 

## 9. **Vendor JavaScript Dependencies**

Third-party libraries are stored in vendor/javascript as ES modules and linked via the manifest: [21](#0-20) 

## **Step-by-Step Replication Guide**

1. **Set up engine with isolated namespace** - Use `isolate_namespace` in your engine class
2. **Add dependencies** - Include turbo-rails, importmap-rails, view_component, and class_variants
3. **Create dual importmaps** - Define separate importmap instances in a class method
4. **Configure asset paths** - Add components directory and vendor/javascript to asset paths
5. **Initialize importmaps in initializer** - Draw importmaps after the main importmap initializer runs
6. **Create helper methods** - Build methods that generate javascript_importmap_tags with your engine's importmaps
7. **Structure Stimulus controllers** - Create an application.js that starts Stimulus, then register controllers with explicit identifiers
8. **Co-locate JS with components** - Put Stimulus controllers in the same directory as ViewComponents
9. **Build component hierarchy** - Create base components that can build child components with view_context
10. **Provide rendering helpers** - Create helper methods that instantiate page/section components and call render
11. **Define theme structure** - Let host apps create layouts that call your render helpers
12. **Link everything via manifest** - Use link_tree directives to expose components and JavaScript to the asset pipeline

## Notes

The critical insight is that **the engine doesn't rely on the host app's importmap at all** - it maintains completely separate importmap instances for editor and client contexts. This allows the engine to control its JavaScript dependencies independently while still being mountable in any Rails app.

The component architecture uses **dependency injection via view_context** - each component receives the view context from its parent, allowing them to render nested components and use Rails helpers without tight coupling.

Stimulus controllers are **explicitly registered** rather than auto-discovered, giving you complete control over namespacing (e.g., "editor-page-preview" vs just "page-preview"). Controllers live alongside their ViewComponents for better organization.

The **theme system** in the host app is decoupled - host apps provide ERB templates in a `theme/` directory, and the engine's components locate and render these templates dynamically based on section type definitions.

### Citations

**File:** lib/maglev/engine.rb (L3-10)
```ruby
require 'turbo-rails'
require 'importmap-rails'
require 'class_variants'
require 'maglev/migration'

module Maglev
  class Engine < ::Rails::Engine
    isolate_namespace Maglev
```

**File:** lib/maglev/engine.rb (L44-49)
```ruby
    def self.importmaps
      @importmaps ||= {
        editor: ::Importmap::Map.new,
        client: ::Importmap::Map.new
      }
    end
```

**File:** lib/maglev/engine.rb (L51-59)
```ruby
    initializer 'maglev.assets' do |app|
      app.config.assets.paths << Engine.root.join('app/assets/builds')
      app.config.assets.paths << Engine.root.join('app/components')
      app.config.assets.paths << Engine.root.join('app/assets/javascripts')
      app.config.assets.paths << Engine.root.join('vendor/javascript')

      # required by Sprockets (if used by the main app)
      app.config.assets.precompile += %w[maglev_manifest]
    end
```

**File:** lib/maglev/engine.rb (L61-82)
```ruby
    initializer 'maglev.importmap', after: 'importmap' do |app|
      Engine.importmaps[:editor].draw(Engine.root.join('config/editor_importmap.rb'))
      Engine.importmaps[:client].draw(Engine.root.join('config/client_importmap.rb'))

      if (Rails.env.development? || Rails.env.test?) && !app.config.cache_classes
        # Editor
        Engine.importmaps[:editor].cache_sweeper(watches: [
                                                   Engine.root.join('app/assets/javascripts'),
                                                   Engine.root.join('app/components')
                                                 ])

        # Client
        Engine.importmaps[:client].cache_sweeper(watches: [
                                                   Engine.root.join('app/assets/javascripts/maglev/client')
                                                 ])

        ActiveSupport.on_load(:action_controller_base) do
          before_action { Engine.importmaps[:editor].cache_sweeper.execute_if_updated }
          before_action { Engine.importmaps[:client].cache_sweeper.execute_if_updated }
        end
      end
    end
```

**File:** maglevcms.gemspec (L42-46)
```text
  # Gems required by the new editor
  spec.add_dependency 'class_variants', '~> 1.1'
  spec.add_dependency 'importmap-rails', '< 3', '>= 2'
  spec.add_dependency 'turbo-rails', '< 3', '>= 2'
  spec.add_dependency 'view_component', '~> 4.1.0'
```

**File:** app/helpers/maglev/application_helper.rb (L12-28)
```ruby
    def maglev_editor_javascript_tags
      maglev_importmap_tags(:editor, 'editor')
    end

    def maglev_client_javascript_tags
      return '' unless maglev_rendering_mode == :editor

      maglev_importmap_tags(:client, 'maglev-client')
    end

    def maglev_importmap_tags(namespace, entry_point)
      safe_join [
        javascript_inline_importmap_tag(Maglev::Engine.importmaps[namespace].to_json(resolver: self)),
        javascript_importmap_module_preload_tags(Maglev::Engine.importmaps[namespace]),
        javascript_import_module_tag(entry_point)
      ], "\n"
    end
```

**File:** app/views/layouts/maglev/editor/application.html.erb (L20-20)
```erb
    <%= maglev_editor_javascript_tags %>
```

**File:** app/views/layouts/maglev/editor/application.html.erb (L55-66)
```erb
      <%= turbo_frame_tag "page-layout" do %>
        <%= yield %>
      <% end %>      

      <%= render 'maglev/editor/sections/toolbar_list' %>
    </div>

    <%= render 'maglev/editor/pages/preview' %>

    <%= turbo_frame_tag "modal" do %>
      <%= yield :modal %> 
    <% end %>
```

**File:** app/assets/javascripts/maglev/editor/index.js (L1-13)
```javascript
import "@hotwired/turbo-rails"
import "maglev-controllers"
import "maglev-patches/page_renderer_patch"
import "maglev-patches/turbo_stream_patch"

console.log('Maglev Editor v2 ⚡️')

// We need to set the content locale in the headers for each Turbo request
document.addEventListener("turbo:before-fetch-request", (event) => {
  const { fetchOptions } = event.detail
  const contentLocale = document.querySelector("meta[name=content-locale]").content
  fetchOptions.headers["X-MAGLEV-LOCALE"] = contentLocale
});
```

**File:** app/assets/javascripts/maglev/editor/controllers/application.js (L1-9)
```javascript
import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
```

**File:** app/assets/javascripts/maglev/editor/controllers/app/index.js (L1-15)
```javascript
import { application } from  "maglev-controllers/application"

import PagePreviewController from "maglev-controllers/app/page_preview_controller"
import PreviewNotificationCenterController from "maglev-controllers/app/preview_notification_center_controller"

import EditorSectionFormController from "maglev-controllers/app/forms/section_form_controller"
import EditorStyleFormController from "maglev-controllers/app/forms/style_form_controller"
import EditorSettingController from "maglev-controllers/app/setting_controller"

application.register("editor-page-preview", PagePreviewController)
application.register("editor-preview-notification-center", PreviewNotificationCenterController)

application.register("editor-section-form", EditorSectionFormController)
application.register("editor-style-form", EditorStyleFormController)
application.register("editor-setting", EditorSettingController)
```

**File:** app/components/maglev/uikit/dropdown_component/dropdown_controller.js (L1-10)
```javascript
import { Controller } from '@hotwired/stimulus'
import { computePosition, flip, shift, size, autoUpdate } from '@floating-ui/dom'
import { useTransition, useClickOutside } from 'stimulus-use'

export default class extends Controller {
  static targets = ['button', 'content']
  static values = { placement: String }
  
  connect() {
    const button = this.buttonTarget
```

**File:** app/components/maglev/base_component.rb (L3-16)
```ruby
module Maglev
  class BaseComponent
    include ::Maglev::Inspector

    extend Forwardable
    def_delegators :view_context, :render

    attr_accessor :view_context

    def build(component_class, attributes)
      component_class.new(**attributes).tap do |component|
        component.view_context = view_context
      end
    end
```

**File:** app/components/maglev/uikit/icon_component.rb (L4-13)
```ruby
  module Uikit
    class IconComponent < ViewComponent::Base
      attr_reader :name, :size, :class_names

      def initialize(name:, size: '1.25rem', class_names: nil)
        @name = name
        @size = size
        @class_names = class_names
      end

```

**File:** app/components/maglev/page_component.rb (L3-17)
```ruby
module Maglev
  class PageComponent < BaseComponent
    attr_reader :site, :theme, :page, :page_sections, :templates_root_path, :config, :rendering_mode

    # rubocop:disable Lint/MissingSuper
    def initialize(site:, theme:, page:, page_sections:, context:)
      @site = site
      @theme = theme
      @page = page
      @page_sections = page_sections
      @templates_root_path = context[:templates_root_path]
      @config = context[:config]
      @rendering_mode = context[:rendering_mode]
    end
    # rubocop:enable Lint/MissingSuper
```

**File:** app/components/maglev/section_component.rb (L55-62)
```ruby
    def render
      super(
        template: "#{templates_root_path}/sections/#{definition.category}/#{type}",
        locals: { section: self, maglev_section: self }
      )
    rescue StandardError => e
      handle_error(e)
    end
```

**File:** spec/dummy/app/views/theme/layout.html.erb (L27-34)
```erb
  <%= maglev_live_preview_client_javascript_tag %>
  <%#= legacy_live_preview_client_javascript_tag %>  
</head>
<body class="flex h-full antialiased">
  <div class="flex w-full">
    <div class="relative flex w-full flex-col lg:px-5">
      <main data-maglev-dropzone>
        <%= render_maglev_sections %>
```

**File:** app/helpers/maglev/page_preview_helper.rb (L5-14)
```ruby
    # rubocop:disable Rails/OutputSafety
    def render_maglev_sections(site: nil, theme: nil, page: nil, page_sections: nil)
      PageComponent.new(
        site: site || maglev_site,
        theme: theme || maglev_theme,
        page: page || maglev_page,
        page_sections: page_sections || maglev_page_sections,
        context: maglev_rendering_context
      ).tap { |component| component.view_context = self }.render.html_safe
    end
```

**File:** spec/dummy/app/views/theme/sections/features/showcase.html.erb (L1-12)
```erb
<%= tag.section class: 'showcase relative py-20 my-20 bg-zinc-100 lg:rounded-4xl', data: section.tag_data do %>
  <div class="relative px-10 mx-auto max-w-7xl xl:px-16">
    <div class="max-w-3xl mx-auto mb-12 text-center lg:mb-20">
      <p><%= section.setting_tag :icon, html_tag: 'i' %></p>

      <%= tag.h2 class: 'mt-3 mb-10 text-4xl font-bold font-heading', data: section.settings.title.tag_data do %>
        <%= raw section.settings.title %>
      <% end %>
    </div>
    
    <ul role="list" class="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-1 sm:gap-x-6 lg:grid-cols-2 xl:gap-x-8">
      <% section.blocks.each do |block| %>
```

**File:** app/assets/config/maglev_manifest.js (L4-6)
```javascript
//= link_tree ../../../vendor/javascript .js
//= link_tree ../../components .js
//= link_tree ../javascripts/maglev .js
```
