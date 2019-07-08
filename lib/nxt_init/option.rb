module NxtInit
  class Option
    InvalidOptionError = Class.new(ArgumentError)

    def initialize(key, default_value: NotProvidedOption.new)
      @key = key
      @default_value = default_value
    end

    attr_reader :key, :default_value

    def resolve(attrs, target:)
      if default_value_was_given?
        key_missing = !attrs.key?(key)
        given_value = attrs[key]

        if default_value_is_preprocessor?
          key_missing ? raise_key_error : target.instance_exec(given_value, &default_value)
        else
          # only when the given value was nil we will evaluate the fallback --> false is a valid value
          if given_value.nil?
            default_value_is_block? ? target.instance_exec(&default_value) : default_value
          else
            given_value
          end
        end
      elsif requires_value?
        attrs.fetch(key) { |_| raise_key_error }
      else
        raise InvalidOptionError, "Don't know how to deal with #{self}"
      end
    end

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

    private

    def raise_key_error
      raise KeyError, "NxtInit attr_init key :#{key} was missing at initialization!"
    end
  end
end