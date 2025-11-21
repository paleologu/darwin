module Darwin::ModelsHelper
  def available_method_names(model)
    runtime_constant = model.runtime_constant
    method_names = %w[attribute]
    if runtime_constant.attribute_names.present?
      method_names << "validates"
    end
    if Darwin::Model.count > 1
      method_names += %w[belongs_to has_many has_one]
    end
    if runtime_constant.reflect_on_all_associations.any?
      method_names << "accepts_nested_attributes_for"
    end
    method_names
  end
end
