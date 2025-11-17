# frozen_string_literal: true

module Darwin
  module Runtime
    module Diagnostics
      def self.install!
        # Track whether we've already installed the hook
        return if @installed

        @installed = true

        # 1️⃣ Warn if Darwin::Runtime is ever reassigned
        Darwin.singleton_class.prepend(Module.new do
          def const_set(name, value)
            if name == :Runtime && const_defined?(:Runtime, false)
              warn "\e[31m[Darwin::Diagnostics]\e[0m Attempted to redefine Darwin::Runtime at #{caller(2,
                                                                                                       3).join("\n  ")}"
              raise 'Darwin::Runtime was redefined! This will break the loader.'
            end
            super
          end
        end)

        # 2️⃣ Wrap Darwin::Runtime.const_set to warn about overwriting classes
        Darwin::Runtime.singleton_class.prepend(Module.new do
          def const_set(name, value)
            warn "\e[33m[Darwin::Diagnostics]\e[0m Overwriting Darwin::Runtime::#{name}" if const_defined?(name, false)
            super
          end
        end)

        # 3️⃣ Add a quick check to confirm the loader remains patched
        return if Darwin::Runtime.respond_to?(:const_missing)

        warn "\e[31m[Darwin::Diagnostics]\e[0m Loader missing! Darwin::Runtime lost its const_missing hook."
      end
    end
  end
end

Darwin::Runtime::Diagnostics.install!
puts 'Loaded diagnostics.rb'
