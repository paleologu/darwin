module Darwin
  class ApplicationController < ::ApplicationController
    layout 'darwin/application'
    # Common behavior for engine controllers
    include Darwin::RoutingHelper
    helper Darwin::RoutingHelper
    helper_method :model_collection_param, :records_path_for, :new_record_path_for, :record_path_for, :edit_record_path_for
  end
end
