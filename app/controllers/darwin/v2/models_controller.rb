module Darwin
	class V2::ModelsController < ApplicationController
		before_action :set_models
		before_action :set_model
		def editor
		end

		def add_column
			unless @model
				return redirect_to(darwin.v2_editor_path, alert: "Model not found")
			end

			column_name = params.dig(:column, :name).to_s.strip
			column_type = params.dig(:column, :type).to_s.strip

			if column_name.blank? || column_type.blank?
				return redirect_to(darwin.v2_editor_path(model_name: @model.name), alert: "Column name and type are required")
			end

			table_name = "darwin_#{@model.name.to_s.tableize}"
			begin
				Darwin::SchemaManager.ensure_column!(table_name, column_name, column_type)
				Darwin::Runtime.reload_all!(current_model: @model, builder: false)
				redirect_to darwin.v2_editor_path(model_name: @model.name), notice: "Column #{column_name} added"
			rescue => e
				redirect_to darwin.v2_editor_path(model_name: @model.name), alert: e.message
			end
		end
		
		private

		def set_model
			@model = Darwin::Model.find_by_name(params[:model_name].capitalize) if params[:model_name]
			puts @model
		end

		def set_models
			@models = Darwin::Model.all
		end
	end
end
