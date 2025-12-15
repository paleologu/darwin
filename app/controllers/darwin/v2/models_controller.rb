module Darwin
	class V2::ModelsController < ApplicationController
		before_action :set_models
		before_action :set_model

		def show
			@blocks = @model.blocks
		end
		def update
		end
		private

		def set_model
			name_param = params[:name].to_s
			candidates = [
				name_param.singularize,
				name_param,
				name_param.tableize.singularize,
				name_param.tableize,
				name_param.camelize.singularize,
				name_param.camelize,
				name_param.underscore.singularize
			].compact.map { |c| c.to_s.downcase }.uniq

			@model = nil
			candidates.each do |candidate|
				@model = Darwin::Model.where('lower(name) = ?', candidate).first
				break if @model
			end

			redirect_to(darwin.models_path, alert: "Model not found") unless @model
		end


		def set_models
			@models = Darwin::Model.all
		end
	end
end
