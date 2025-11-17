# frozen_string_literal: true

module Darwin
  module Runtime
    module Loader
      module_function

      # Called automatically whenever a constant is missing inside Darwin::Runtime
      def const_missing(name)
        # Example: `Article` or `Blog::Post`
        model_name = name.to_s

        # Try to find a model in the DB that matches this constant
        model = Darwin::Model.find_by(name: model_name.underscore)

        raise NameError, "uninitialized constant Darwin::Runtime::#{model_name}" unless model

        # Build or reload the class dynamically
        Darwin::Interpreter.evaluate_model_blocks(model)

        # Return the newly defined constant
        Darwin::Runtime.const_get(name)
      end
    end
  end
end

# Hook it into the constant lookup chain
Darwin::Runtime.singleton_class.prepend(Darwin::Runtime::Loader)
puts 'Loaded loader.rb'
