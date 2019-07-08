require "nxt_init/version"
require "nxt_init/option"
require 'active_support'

module NxtInit
  InvalidOptionError = Class.new(ArgumentError)

  module ClassMethods
    def attr_init(*args)
      options = build_options(*args)
      self.attr_init_opts ||= []
      self.attr_init_opts = merge_options(attr_init_opts, options)

      define_private_readers(*options.map(&:key))
    end

    attr_accessor :attr_init_opts

    private

    def inherited(subclass)
      subclass.attr_init_opts = attr_init_opts.map(&:dup)
    end

    def merge_options(existing_options, new_options)
      all_option_keys = (existing_options + new_options).map(&:key)

      all_option_keys.uniq.each_with_object([]) do |key, merged_options|
        merged_options << new_options.find { |opt| opt.key == key } || existing_options.find { |opt| opt.key == key }
      end
    end

    def define_private_readers(*keys)
      attr_reader *keys
      private *keys
    end

    def build_options(*args)
      options_hash = *args.extract_options!
      args = args.map { |arg| Option.new(arg) }
      options_hash.each { |key, value| args << Option.new(key, default_value: value) }
      args
    end
  end

  module InstanceMethods
    def initialize(*args, **attrs)
      option_keys = self.class.send(:attr_init_opts).map(&:key)

      attr_init_opts = attrs.slice(*option_keys)
      other_options = attrs.slice!(*option_keys)
      # passing **{} is like calling super({}) which does not work when super does not except arguments#
      initialize_attrs_from_options(**attr_init_opts)
      other_options.empty? ? super(*args) : super(*args, **other_options)
    end

    private

    def initialize_attrs_from_options(**attrs)
      self.class.send(:attr_init_opts).each do |opt|
        if opt.default_value_was_given?
          default_value = opt.default_value
          given_value = attrs[opt.key]
          key_missing = !attrs.key?(opt.key)

          if opt.default_value_is_preprocessor?
            value = key_missing ? raise_key_error(opt.key) : instance_exec(given_value, &default_value)
          else
            # only when the given value was nil we will evaluate the fallback --> false is a valid value
            value = if given_value.nil?
              opt.default_value_is_block? ? instance_exec(&default_value) : default_value
            else
              given_value
            end
          end
        elsif opt.requires_value?
          value = attrs.fetch(opt.key) { |k| raise_key_error(k) }
        else
          raise InvalidOptionError, "Don't know how to deal with #{opt}"
        end
        instance_variable_set("@#{opt.key}", value)
      end
    end

    def raise_key_error(key)
      raise KeyError, "NxtInit attr_init key :#{key} was missing at initialization!"
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
  end
end
