class Darwin::ModelsController < Darwin::ApplicationController
  include Rails.application.routes.url_helpers
  before_action :set_model, only: [:show, :edit, :update, :destroy, :attribute_type]

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

  private
  def set_model
    name_param = params[:name].to_s
    @model = Darwin::Model.where('lower(name) = ?', name_param.underscore).first ||
             Darwin::Model.find_by(name: name_param.camelize)
    unless @model
      redirect_to darwin.models_path, alert: "Model not found"
    end
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
