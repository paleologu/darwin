module Darwin::ModelsHelper
  def available_method_names(model)
    block_type_options(model).map(&:primary_name)
  end

  def block_type_options(model)
    runtime_constant = runtime_class_for(model)
    Darwin::BlockHandlerRegistry.ui_handlers(model:, runtime_class: runtime_constant)
  end

  def runtime_class_for(model)
    return nil unless model

    @runtime_class_cache ||= {}
    cache_key = model.persisted? ? model.id : model.object_id
    @runtime_class_cache[cache_key] ||= begin
      result = Darwin::RuntimeAccessor::Service.call(model:, force_reload: true)
      result.success? ? result.data[:runtime_class] : nil
    end
  end

end
