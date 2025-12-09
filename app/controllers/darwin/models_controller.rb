class Darwin::ModelsController < Darwin::ApplicationController
  include Rails.application.routes.url_helpers
  before_action :set_model, only: [:show, :edit, :update, :destroy, :attribute_type]

  def index
    @models = Darwin::Model.all
  end

  def new
    @model = Darwin::Model.new
  end

  def create
    @model = Darwin::Model.new(model_params)
    if @model.save!
      redirect_to darwin.models_path, notice: 'Model was successfully created.'
    else
      @blocks = @model.blocks
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @records = @model.runtime_constant.all
  end

  def edit
  end

  def update
    if @model.update!(model_params)
      redirect_to darwin.model_path(@model), notice: 'Model was successfully updated.'
    else
      @blocks = @model.blocks
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @model.destroy
    redirect_to darwin.models_path, notice: 'Model was successfully destroyed.'
  end


  def attribute_type
    column = @model.runtime_constant.columns_hash[params[:attribute_name]]
    render json: { type: column&.type }
  end

  private
  def set_model
    @model = Darwin::Model.find_by!(name: params[:name].singularize.classify)
    # Works for models like car => cars, girl => girls but not for adsfg
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
