module Darwin
	class V2::ModelsController < ApplicationController
		before_action :set_models
		before_action :set_model
		def editor
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