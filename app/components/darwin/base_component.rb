# frozen_string_literal: true

module Darwin
  class BaseComponent
    attr_accessor :view_context

    def build(component_class, **attributes)
      component_class.new(**attributes).tap do |component|
        component.view_context = view_context if component.respond_to?(:view_context=)
      end
    end
  end
end
