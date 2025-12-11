class Darwin::BlocksController < ApplicationController
  before_action :set_model

  def new
    @block = @model.blocks.new(method_name: params[:method_name])
  end

  def create
    if params[:darwin_block][:args_name].blank?
      @block = @model.blocks.new(block_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("blocks", partial: "darwin/blocks/form", locals: { block: @block })
        end
      end
    else
      permitted = block_params.to_h

      if permitted["method_name"] == "validates"
        attr_name = permitted["args_name"]
        attr_type = attribute_type_for(@model, attr_name)
        validation = pick_validation_for(attr_type)
        permitted["validation_type"] ||= validation
        permitted["options"] ||= default_options_for(validation)
      end

      result = Darwin::BlockBuilder::Create::Service.call(model: @model, params: permitted)
      @block = result.data[:block] if result.success?

      if result.success?
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace("new_block_form", partial: "darwin/blocks/block", locals: { block: @block })
          end
          format.html do
            redirect_to darwin.edit_model_path(@model), notice: "Validation added to #{@block.args_name}"
          end
        end
      else
        @block ||= @model.blocks.new(block_params)
        flash.now[:alert] = result.error.message if result.respond_to?(:error) && result.error
        respond_to do |format|
          format.turbo_stream { render :new, status: :unprocessable_entity }
          format.html { redirect_to darwin.edit_model_path(@model), alert: flash.now[:alert] || "Could not create block" }
        end
      end
    end
  end

  def destroy
    block = @model.blocks.find(params[:id])
    dom_id = ActionView::RecordIdentifier.dom_id(block)
    result = Darwin::BlockBuilder::Destroy::Service.call(model: @model, block_id: params[:id])
    if result.success?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.remove(dom_id)
        end
      end
    else
      render plain: result.error.message, status: :unprocessable_entity
    end
  end

  private

  def set_model
    @model = Darwin::Model.find_by(name: params[:model_name].singularize.classify)
  end

  def block_params
    params.require(:darwin_block).permit(
      :method_name, :args_name, :args_type, :validation_type, { args: [] }, :position,
      options: [
        :presence, :numericality, :uniqueness,
        { length: [:minimum, :maximum] },
        { format: [:with] },
        { inclusion: [:in] },
        { exclusion: [:in] }
      ]
    )
  end

  def attribute_type_for(model, attr_name)
    runtime = Darwin::RuntimeAccessor::Service.call(model:, force_reload: false)
    runtime_class = runtime.success? ? runtime.data[:runtime_class] : nil
    runtime_class&.columns_hash&.dig(attr_name)&.type&.to_s
  end

  def pick_validation_for(attr_type)
    matrix = {
      "string" => %w[presence length format uniqueness inclusion exclusion],
      "text" => %w[presence length uniqueness inclusion exclusion],
      "integer" => %w[presence numericality uniqueness inclusion exclusion],
      "float" => %w[presence numericality uniqueness inclusion exclusion],
      "decimal" => %w[presence numericality uniqueness inclusion exclusion],
      "boolean" => %w[inclusion exclusion],
      "date" => %w[presence],
      "datetime" => %w[presence]
    }
    ordered = %w[presence numericality uniqueness length format inclusion exclusion]
    allowed = matrix[attr_type] || []
    (ordered & allowed).first
  end

  def default_options_for(validation)
    case validation
    when "presence" then { "presence" => true }
    when "numericality" then { "numericality" => true }
    when "uniqueness" then { "uniqueness" => true }
    when "length" then { "length" => { "minimum" => nil, "maximum" => nil } }
    when "format" then { "format" => { "with" => nil } }
    when "inclusion" then { "inclusion" => { "in" => [] } }
    when "exclusion" then { "exclusion" => { "in" => [] } }
    else {}
    end
  end
end
