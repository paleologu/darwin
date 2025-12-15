class Darwin::ModelsController < Darwin::ApplicationController
  include Rails.application.routes.url_helpers
  before_action :set_model, only: [:show, :edit, :update, :destroy, :attribute_type, :add_column, :update_column, :destroy_column]

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
    if result.success?
      redirect_to(darwin.edit_model_path(result.data[:model]), notice: 'Model was successfully created.') 
    else
      @model = result.data[:model] || Darwin::Model.new(model_params)
      @blocks = @model.blocks
      flash.now[:alert] = result.error.message
      render :new, status: :unprocessable_entity
    end
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
    result = Darwin::RuntimeAccessor::Service.call(model: @model)
    unless result.success?
      render json: { error: result.error&.message || "Runtime unavailable" }, status: :unprocessable_entity
      return
    end

    runtime = result.data[:runtime_class]
    column = runtime.columns_hash[params[:attribute_name]]
    render json: { type: column&.type }
  end

  def add_column
    return if performed?
    @column = @model.columns.new(column_params)

    if @column.save!
      begin
        Darwin::SchemaSyncJob.run(model_id: @model.id, action: 'sync', builder: true)
        @model.reload
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "columns-list",
              partial: "darwin/models/table/columns",
              locals: { model: @model }
              )
          end
          format.html do
            redirect_to darwin.edit_model_path(@model), notice: "Column #{@column.name} added"
          end
        end
      rescue StandardError => e
        handle_column_error(e.message)
      end
    else
      handle_column_error(@column.errors.full_messages.to_sentence)
    end
  end

  def update_column
    return if performed?

    @column = @model.columns.find_by(id: params[:id])
    return handle_column_error("Column not found") unless @column

    if @column.update!(column_params)
      begin
        Darwin::SchemaSyncJob.run(model_id: @model.id, action: 'sync', builder: true)
        @model.reload
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "columns-list",
              partial: "darwin/models/table/columns",
              locals: { model: @model }
              )
          end
          format.html do
            redirect_to darwin.edit_model_path(@model), notice: "Column #{@column.name} updated"
          end
        end
      rescue StandardError => e
        handle_column_error(e.message)
      end
    else
      handle_column_error(@column.errors.full_messages.to_sentence)
    end
  end

  def destroy_column
    return if performed?

    @column = @model.columns.find_by(id: params[:id])
    return handle_column_error("Column not found") unless @column

    if @column.destroy
      begin
        Darwin::SchemaSyncJob.run(model_id: @model.id, action: 'sync', builder: true)
        @model.reload
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "columns-list",
              partial: "darwin/models/table/columns",
              locals: { model: @model }
              )
          end
          format.html do
            redirect_to darwin.edit_model_path(@model), notice: "Column removed"
          end
        end
      rescue StandardError => e
        handle_column_error(e.message)
      end
    else
      handle_column_error(@column.errors.full_messages.to_sentence)
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

  def column_params
    permitted = params.require(:column).permit(:name, :type, :column_type, :default, :null, :limit, :precision, :scale)
    permitted[:column_type] ||= permitted.delete(:type)
    permitted[:default] = nil if permitted[:default].is_a?(String) && permitted[:default].strip.empty?
    %i[limit precision scale].each do |key|
      permitted[key] = nil if permitted[key].respond_to?(:empty?) && permitted[key].empty?
    end
    permitted[:null] = ActiveModel::Type::Boolean.new.cast(permitted[:null]) if permitted.key?(:null)
    permitted
  end

  def handle_column_error(message)
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = message
        render turbo_stream: turbo_stream.replace(
          "flash",
          partial: "layouts/flash"
          ), status: :unprocessable_entity
      end
      format.html do
        redirect_to darwin.edit_model_path(@model), alert: message
      end
    end
  end
end
