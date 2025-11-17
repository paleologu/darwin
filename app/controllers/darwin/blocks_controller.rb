class Darwin::BlocksController < ApplicationController
  before_action :set_model

  def new
    @block = @model.blocks.new(block_type: params[:block_type])
  end

  def create
    if params[:darwin_block][:args_name].present?
      @block = @model.blocks.new(block_params)
      if @block.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace("new_block_form", partial: "darwin/blocks/block", locals: { block: @block })
          end
        end
      else
        render :new, status: :unprocessable_entity
      end
    else
      @block = @model.blocks.new(block_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("blocks", partial: "darwin/blocks/form", locals: { block: @block })
        end
      end
    end
  end

  def destroy
    @block = @model.blocks.find(params[:id])
    @block.destroy
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_model
    @model = Darwin::Model.find_by(name: params[:model_name].singularize.classify)
  end

  def block_params
    params.require(:darwin_block).permit(
      :block_type, :args_name, :args_type, :validation_type, { args: [] }, :position,
      options: [
        :presence, :numericality, :uniqueness,
        { length: [:minimum, :maximum] },
        { format: [:with] },
        { inclusion: [:in] },
        { exclusion: [:in] }
      ]
    )
  end
end