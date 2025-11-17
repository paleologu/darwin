module Darwin::ModelsHelper
  def available_block_types(model)
    runtime_constant = model.runtime_constant
    block_types = %w[attribute]
    if runtime_constant.attribute_names.present?
      block_types << "validates"
    end
    if Darwin::Model.count > 1
      block_types += %w[belongs_to has_many has_one]
    end
    if runtime_constant.reflect_on_all_associations.any?
      block_types << "accepts_nested_attributes_for"
    end
    block_types
  end
end
