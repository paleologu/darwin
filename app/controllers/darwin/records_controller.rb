class Darwin::RecordsController < Darwin::ApplicationController
  include Rails.application.routes.url_helpers
  before_action :set_model
  before_action :set_runtime_class
  def index
    return if performed?

    @records = @runtime_class.all
  end

  def show
    return if performed?

    @record = @runtime_class.find(params[:id])
  end

  def new
    return if performed?

    @record = @runtime_class.new
    # Build one of each nested association that accepts nested attributes
    @runtime_class.reflect_on_all_associations(:has_many).each do |association|
      if @runtime_class.nested_attributes_options.key?(association.name)
        @record.send(association.name).build
      end
    end
  end

  def create
    return if performed?

    @record = @runtime_class.new(record_params)
    return redirect_to(record_path_for(@model, @record), notice: 'Record was successfully created.') if @record.save!

    render :new, status: :unprocessable_entity
  end

  def edit
    return if performed?

    @record = @runtime_class.find(params[:id])
    # Build one of each nested association that accepts nested attributes if none exist
    @runtime_class.reflect_on_all_associations(:has_many).each do |association|
      if @runtime_class.nested_attributes_options.key?(association.name)
        @record.send(association.name).build if @record.send(association.name).empty?
      end
    end
  end

  def update
    return if performed?

    @record = @runtime_class.find(params[:id])
    return redirect_to(record_path_for(@model, @record), notice: 'Record was successfully updated.') if @record.update!(record_params)

    render :edit, status: :unprocessable_entity
  end

  def destroy
    return if performed?

    @record = @runtime_class.find(params[:id])
    @record.destroy
    redirect_to records_path_for(@model), notice: 'Record was successfully destroyed.'
  end

  private

  def set_model
    @model = Darwin::Model.find_by!(name: params[:model_name].singularize.classify)
  end

  def set_runtime_class
    result = Darwin::RuntimeAccessor::Service.call(model: @model)
    if result.success?
      @runtime_class = result.data[:runtime_class]
    else
      redirect_to darwin.models_path, alert: result.error.message
      return
    end
  end

  def record_params
    # Permit all attributes of the runtime class.
    # Permit all `_attributes` from associations that `accepts_nested_attributes_for`.
    permitted_params = @runtime_class.attribute_names.map(&:to_sym)
    param_key = @runtime_class.model_name.param_key.to_sym
    @runtime_class.reflect_on_all_associations.each do |association|
      if @runtime_class.nested_attributes_options.key?(association.name)
        permitted_params << {"#{association.name}_attributes".to_sym => [:id, :_destroy, *association.klass.attribute_names.map(&:to_sym)]}
      end
    end
    params.require(param_key).permit(*permitted_params)
  end
end
