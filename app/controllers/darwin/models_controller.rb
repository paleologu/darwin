class Darwin::ModelsController < Darwin::ApplicationController
  include Rails.application.routes.url_helpers
  before_action :set_model, only: [:show, :edit, :update, :destroy, :attribute_type, :add_column]

  def index
    @models = Darwin::Model.all
  end

  def new
    result = Darwin::ModelBuilder::Build::Service.call
    if result.success?
      @model = result.data[:model]
    else
      redirect_to darwin.models_path, alert: result.error.message
    end
  end

  def create
    result = Darwin::ModelBuilder::Create::Service.call(params: model_params)
    return redirect_to(darwin.models_path, notice: 'Model was successfully created.') if result.success?

    @model = result.data[:model] || Darwin::Model.new(model_params)
    @blocks = @model.blocks
    flash.now[:alert] = result.error.message
    render :new, status: :unprocessable_entity
  end

  def show
    return if performed?

    @runtime_class = runtime_for(@model)
    return if performed?

    @records = @runtime_class.all
  end

  def edit
    return if performed?

    @runtime_class = runtime_for(@model)
  end

  def update
    return if performed?

    result = Darwin::ModelBuilder::Update::Service.call(model: @model, params: model_params)
    return redirect_to(darwin.model_path(@model), notice: 'Model was successfully updated.') if result.success?

    @model = result.data[:model] || @model
    @blocks = @model.blocks
    flash.now[:alert] = result.error.message
    render :edit, status: :unprocessable_entity
  end

  def destroy
    return if performed?

    result = Darwin::ModelBuilder::Destroy::Service.call(model: @model)
    if result.success?
      redirect_to darwin.models_path, notice: 'Model was successfully destroyed.'
    else
      redirect_to darwin.models_path, alert: result.error.message
    end
  end


  def attribute_type
    return if performed?

    runtime = runtime_for(@model)
    return if performed?

    column = runtime.columns_hash[params[:attribute_name]]
    render json: { type: column&.type }
  end

  def add_column
    return if performed?
    column_name = params.dig(:column, :name).to_s.strip
    column_type = params.dig(:column, :type).to_s.strip
    if column_name.blank? || column_type.blank?
      return redirect_to(darwin.edit_model_path(@model), alert: "Column name and type are required")
    end

    table_name = "darwin_#{@model.name.to_s.tableize}"
    begin
      Darwin::SchemaManager.ensure_column!(table_name, column_name, column_type)
      Darwin::Runtime.reload_all!(current_model: @model, builder: false)
      @runtime_class = runtime_for(@model, redirect_on_failure: false)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "columns-list",
            partial: "darwin/models/table/columns",
            locals: { runtime_class: @runtime_class }
          )
        end
        format.html do
          redirect_to darwin.edit_model_path(@model), notice: "Column #{column_name} added"
        end
      end
    rescue => e
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = e.message
          render turbo_stream: turbo_stream.replace(
            "flash",
            partial: "layouts/flash"
          ), status: :unprocessable_entity
        end
        format.html do
          redirect_to darwin.edit_model_path(@model), alert: e.message
        end
      end
    end
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

  def runtime_for(model, redirect_on_failure: true)
    runtime_result = Darwin::RuntimeAccessor::Service.call(model:)
    return runtime_result.data[:runtime_class] if runtime_result.success?

    redirect_to(darwin.models_path, alert: runtime_result.error.message) if redirect_on_failure
    nil
  end

  def model_params
    # The `Darwin::Block` model's `before_validation` callback assembles the `args`
    # array from `args_name` and `args_type` for attribute blocks.
    params.require(:darwin_model).permit(
      :name,
      blocks_attributes: [
        :id, :method_name, :args_name, :args_type, { args: [] }, :position, :_destroy,
        { options: [:default, :null, :limit, :precision, :scale] }
      ]
    )
  end
end
