class Darwin::RecordsController < ApplicationController
  include Rails.application.routes.url_helpers
  before_action :set_model

  def index
    @records = @model.runtime_class.all
  end

  def show
    @record = @model.runtime_class.find(params[:id])
  end

  def new
    @record = @model.runtime_class.new
    # Build one of each nested association that accepts nested attributes
    @model.runtime_class.reflect_on_all_associations(:has_many).each do |association|
      if @model.runtime_class.nested_attributes_options.key?(association.name)
        @record.send(association.name).build
      end
    end
  end

  def create
    @record = @model.runtime_class.new(record_params)
    if @record.save
      redirect_to darwin.record_path(@model.name.pluralize.underscore, @record), notice: 'Record was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @record = @model.runtime_class.find(params[:id])
    # Build one of each nested association that accepts nested attributes if none exist
    @model.runtime_class.reflect_on_all_associations(:has_many).each do |association|
      if @model.runtime_class.nested_attributes_options.key?(association.name)
        @record.send(association.name).build if @record.send(association.name).empty?
      end
    end
  end

  def update
    @record = @model.runtime_class.find(params[:id])
    if @record.update(record_params)
      redirect_to darwin.record_path(@model.name.pluralize.underscore, @record), notice: 'Record was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @record = @model.runtime_class.find(params[:id])
    @record.destroy
    redirect_to darwin.records_path(@model.name.pluralize.underscore), notice: 'Record was successfully destroyed.'
  end

  private

  def set_model
    @model = Darwin::Model.find_by!(name: params[:model_name].singularize.classify)
  end

  def record_params
    # Permit all attributes of the runtime class.
    # Permit all `_attributes` from associations that `accepts_nested_attributes_for`.
    permitted_params = @model.runtime_class.attribute_names.map(&:to_sym)
    param_key = @model.runtime_class.model_name.param_key.to_sym
    @model.runtime_class.reflect_on_all_associations.each do |association|
      if @model.runtime_class.nested_attributes_options.key?(association.name)
        permitted_params << {"#{association.name}_attributes".to_sym => [:id, :_destroy, *association.klass.attribute_names.map(&:to_sym)]}
      end
    end
    params.require(param_key).permit(*permitted_params)
  end
end
