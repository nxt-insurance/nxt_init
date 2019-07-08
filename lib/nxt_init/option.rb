module NxtInit
  class Option
    def initialize(key, default_value: NotProvidedOption.new)
      @key = key,
      @default_value = default_value
    end

    attr_reader :key, :default_value

    def requires_value?
      !default_value_was_given?
    end

    def default_value_is_block?
      default_value && default_value.respond_to?(:call)
    end

    def default_value_is_preprocessor?
      default_value_is_block? && default_value.arity == 1
    end

    def default_value_was_given?
      !default_value.is_a?(NotProvidedOption)
    end
  end
end