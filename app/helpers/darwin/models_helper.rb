module Darwin::ModelsHelper
  def available_method_names(model)
    runtime_constant = runtime_class_for(model)
    method_names = %w[attribute]
    if runtime_constant && runtime_constant.attribute_names.present?
      method_names << "validates"
    end
    if Darwin::Model.count > 1
      method_names += %w[belongs_to has_many has_one]
    end
    if runtime_constant && runtime_constant.reflect_on_all_associations.any?
      method_names << "accepts_nested_attributes_for"
    end
    method_names
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
