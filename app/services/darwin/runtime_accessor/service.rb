# frozen_string_literal: true

module Darwin
  module RuntimeAccessor
    require 'servus'

    class Service < Servus::Base
      def initialize(model: nil, model_name: nil, force_reload: false)
        @model = model
        @model_name = model_name
        @force_reload = force_reload
      end

      def call
        model = @model || find_model(@model_name)
        return failure('Model not found') unless model

        reload_runtime if @force_reload || !runtime_defined?(model)

        klass = fetch_runtime_class(model)
        return failure('Runtime class missing after reload', model:) unless klass

        success(model:, runtime_class: klass)
      rescue StandardError => e
        failure(e.message)
      end

      private

      def find_model(name)
        return nil if name.blank?

        Darwin::Model.find_by(name: name.to_s.classify)
      end

      def runtime_defined?(model)
        Darwin::Runtime.const_defined?(model.name.classify, false)
      end

      def fetch_runtime_class(model)
        Darwin::Runtime.const_get(model.name.classify) if runtime_defined?(model)
      end

      def reload_runtime
        Darwin::Runtime.reload_all!(builder: true)
      end
    end
  end
end
