# frozen_string_literal: true

module Darwin
  class BlockFormPresenter
    attr_reader :block, :builder, :view_context

    def initialize(block:, builder:, view_context:)
      @block = block
      @builder = builder
      @view_context = view_context
    end

    def handler
      @handler ||= Darwin::BlockHandlers.for(block)
    end

    def container_attributes
      base = { data: { 'block-form-target': 'fields' }, class: 'space-y-4' }
      extra = handler&.form_attributes(block, view_context:) || {}
      merge_attributes(base, extra)
    end

    def render
      return ''.html_safe unless block&.method_name && handler

      fields = handler.form_fields(block, view_context:)
      view_context.safe_join(fields.map { |field| render_field(field) })
    end

    private

    def render_field(field, scoped_builder: builder)
      case field[:component]
      when :group
        attributes = normalize_attributes(field[:wrapper_attributes])
        content = view_context.safe_join(field.fetch(:fields, []).map { |child| render_field(child, scoped_builder:) })
        return view_context.tag.div(content, **attributes)
      when :hidden
        return with_builder(field[:scope], scoped_builder) do |form_builder, _object|
          form_builder.hidden_field(field[:name], value: field[:value], data: field[:data])
        end
      when :input_group
        return render_input_group(field, scoped_builder:)
      end

      with_builder(field[:scope], scoped_builder) do |form_builder, object|
        render_wrapped_field(field, form_builder:, object:)
      end
    end

    def render_input_group(field, scoped_builder:)
      content_attributes = normalize_attributes(field[:content_classes] ? { class: field[:content_classes] } : {})
      wrapper_attributes = normalize_attributes(field[:wrapper_attributes])

      view_context.render('ui/field', attributes: wrapper_attributes) do
        view_context.safe_join(
          [
            field[:label] ? view_context.render('ui/field/label') { field[:label] } : nil,
            view_context.render('ui/field/content', **content_attributes) do
              view_context.safe_join(
                field.fetch(:inputs, []).map do |input|
                  with_builder(input[:scope], scoped_builder) do |form_builder, object|
                    input_id = form_builder.field_id(input[:name]) if form_builder.respond_to?(:field_id)
                    render_input(input, form_builder:, object:, input_id:)
                  end
                end
              )
            end
          ].compact
        )
      end
    end

    def render_wrapped_field(field, form_builder:, object:)
      field_attributes = normalize_attributes(field[:wrapper_attributes])
      content_attributes = normalize_attributes(field[:content_attributes])
      label_options = normalize_attributes(field[:label_options])
      content_attributes = merge_attributes(content_attributes, class: field[:content_classes]) if field[:content_classes]
      input_id = form_builder.field_id(field[:name]) if form_builder.respond_to?(:field_id)

      field_content = render_input(field, form_builder:, object:, input_id:)

      view_context.render('ui/field', attributes: field_attributes) do
        view_context.safe_join(
          [
            (field[:label] ? view_context.render('ui/field/label', **label_options.merge(for_id: input_id)) { field[:label] } : nil),
            view_context.render('ui/field/content', **content_attributes) { field_content },
            render_errors(field, object),
            (field[:description] ? view_context.render('ui/field/description', content: field[:description]) : nil)
          ].compact
        )
      end
    end

    def render_input(field, form_builder:, object:, input_id:)
      case field[:component]
      when :input
        value = field.key?(:value) ? field[:value] : fetch_value(object, field[:name])
        view_context.render('ui/input',
                            id: input_id,
                            name: form_builder.field_name(field[:name]),
                            value: value,
                            type: field[:type],
                            placeholder: field[:placeholder])
      when :switch
        render_switch(field, form_builder:, object:, input_id:)
      when :select
        render_select(field, form_builder:, object:, input_id:)
      else
        ''
      end
    end

    def render_switch(field, form_builder:, object:, input_id:)
      hidden_input = if field[:hidden_value]
                       form_builder.hidden_field(field[:name], value: field[:hidden_value])
                     end
      checked = field.key?(:checked) ? field[:checked] : fetch_value(object, field[:name])
      switch = view_context.render('ui/switch',
                                   id: input_id,
                                   name: form_builder.field_name(field[:name]),
                                   checked: checked,
                                   data: field[:data])

      content_attrs = normalize_attributes(field[:content_attributes])
      content_attrs = merge_attributes(content_attrs, class: field[:content_classes]) if field[:content_classes]

      view_context.safe_join([(hidden_input if field[:hidden_value]), switch].compact)
    end

    def render_select(field, form_builder:, object:, input_id:)
      value = field.key?(:value) ? field[:value] : fetch_value(object, field[:name])
      select_data = field[:select_data] || {}
      hidden_data = { 'ui--select-target': 'hiddenInput' }.merge(field[:hidden_data] || {})
      content_classes = field[:content_classes]
      trigger_classes = field[:trigger_classes]

      select_body = view_context.render('ui/select', value:, classes: content_classes, data: select_data) do
        view_context.safe_join(
          [
            view_context.render('ui/select/trigger', placeholder: field[:placeholder], classes: trigger_classes),
            view_context.render('ui/select/content') do
              view_context.safe_join(field[:collection].map do |item|
                view_context.render('ui/select/item', value: item[:value], attributes: normalize_attributes(data: item[:data])) do
                  item[:label] || item[:value].to_s.titleize
                end
              end)
            end,
            form_builder.hidden_field(field[:name], value:, data: hidden_data, id: input_id)
          ]
        )
      end

      select_body
    end

    def render_errors(field, object)
      key = field[:error_key] || field[:name]
      return unless object.respond_to?(:errors)

      errors = object.errors.full_messages_for(key)
      return if errors.empty?

      view_context.render('ui/field/error', content: errors.join(', '))
    end

    def fetch_value(object, name)
      if object.respond_to?(name)
        object.public_send(name)
      elsif object.respond_to?(:[])
        object[name.to_s] || object[name]
      end
    end

    def with_builder(scope, current_builder)
      return yield(current_builder, current_builder.object) unless scope

      scopes = Array(scope)
      build_nested_builder(scopes, current_builder, current_builder.object) { |builder, obj| yield(builder, obj) }
    end

    def build_nested_builder(scopes, current_builder, object, &block)
      name = scopes.first
      value = fetch_value(object, name) || {}
      content = nil

      current_builder.fields_for(name, value) do |nested_builder|
        if scopes.one?
          content = block.call(nested_builder, value)
        else
          content = build_nested_builder(scopes.drop(1), nested_builder, value, &block)
        end
      end

      content
    end

    def normalize_attributes(attributes)
      attrs = attributes || {}
      attrs = attrs.transform_keys(&:to_sym)
      attrs[:data] = attrs[:data].transform_keys(&:to_s) if attrs[:data]
      attrs
    end

    def merge_attributes(base, extra)
      merged = base.deep_dup
      extra.each do |key, value|
        case key.to_sym
        when :class
          merged[:class] = [merged[:class], value].compact.flat_map { |cls| cls.to_s.split(' ') }.uniq.join(' ')
        when :data
          merged[:data] = (merged[:data] || {}).merge(value || {})
        else
          merged[key] = value
        end
      end
      merged
    end
  end
end
