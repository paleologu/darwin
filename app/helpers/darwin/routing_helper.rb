# frozen_string_literal: true

module Darwin
  module RoutingHelper
    def model_collection_param(model)
      return model.collection_param if model.respond_to?(:collection_param)

      model.to_s
    end

    def records_path_for(model)
      darwin.records_path(model_collection_param(model))
    end

    def new_record_path_for(model)
      darwin.new_record_path(model_collection_param(model))
    end

    def record_path_for(model, record)
      darwin.record_path(model_collection_param(model), record)
    end

    def edit_record_path_for(model, record)
      darwin.edit_record_path(model_collection_param(model), record)
    end
  end
end
