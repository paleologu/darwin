module Darwin
  class V2::Models::BlocksController < ApplicationController
    before_action :set_model, only: %w[create update]

    def create
      @block = @model.blocks.build(block_params)

      if @block.save
        respond_to do |format|
          format.turbo_stream { render_block_list }
          format.html { redirect_to darwin.edit_v2_model_path(@model) }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              view_context.dom_id(@model, :new_block),
              partial: "darwin/v2/models/new_block_form",
              locals: { model: @model, block: @block }
            ), status: :unprocessable_entity
          end
          format.html { redirect_to darwin.edit_v2_model_path(@model), alert: @block.errors.full_messages.to_sentence }
        end
      end
    end

    def update
      @block = @model.blocks.find(params[:id])

      if @block.update(block_params)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              view_context.dom_id(@block),
              partial: "darwin/v2/models/block",
              locals: { block: @block, model: @model }
            )
          end
          format.html { redirect_to darwin.edit_v2_model_path(@model) }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              view_context.dom_id(@block),
              partial: "darwin/v2/models/block",
              locals: { block: @block, model: @model }
            ), status: :unprocessable_entity
          end
          format.html { redirect_to darwin.edit_v2_model_path(@model), alert: @block.errors.full_messages.to_sentence }
        end
      end
    end

    private

    def set_model
      name_param = params[:name].presence || params[:model_name].to_s
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

    def block_params
      permitted = params.require(:block).permit(:method_name, :options, args: [])
      raw_args = params.dig(:block, :args)
      permitted[:args] = raw_args if permitted[:args].blank? && raw_args.present?
      permitted
    end

    def render_block_list
      @model.reload
      render turbo_stream: turbo_stream.replace(
        view_context.dom_id(@model, :blocks),
        partial: "darwin/v2/models/block_list",
        locals: { model: @model }
      )
    end
  end
end
