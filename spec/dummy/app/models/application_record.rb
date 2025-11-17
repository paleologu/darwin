class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  def to_s
    return name if respond_to?(:name)
    return title if respond_to?(:title)
    "#{self.class.name} ##{id}"
  end
end