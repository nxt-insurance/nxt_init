require "nxt_init/version"
require 'active_support'

module NxtInit
  InvalidOptionError = Class.new(ArgumentError)

  module ClassMethods
    def attr_init(*args)
      flat_args = flatten_options(*args)
      self.attr_init_opts ||= []
      self.attr_init_opts += flat_args
      define_private_readers(*flat_args)
    end

    attr_accessor :attr_init_opts

    private

    def inherited(subclass)
      subclass.attr_init_opts = attr_init_opts.map(&:dup)
    end

    def define_private_readers(*args)
      keys = args.map { |attr| attr.is_a?(Hash) ? attr.keys.first : attr }
      attr_reader *keys
      private *keys
    end

    def flatten_options(*args)
      options_hash = *args.extract_options!
      options_hash.each { |key, value| args << {"#{key}": value} }
      args
    end
  end

  module InstanceMethods
    def initialize(*args, **attrs)
      option_keys = self.class.send(:attr_init_opts).map do |option|
        option.is_a?(Hash) ? option.keys.first : option
      end

      attr_init_opts = attrs.slice(*option_keys)
      other_options = attrs.slice!(*option_keys)
      # passing **{} is like calling super({}) which does not work when super does not except arguments
      initialize_attrs_from_options(**attr_init_opts)
      other_options.empty? ? super(*args) : super(*args, **other_options)
    end

    private

    def initialize_attrs_from_options(**attrs)
      self.class.send(:attr_init_opts).each do |opt|
        if opt.is_a?(Hash)
          key = opt.keys.first
          value = opt.values.first
          value = attrs[key] || (value.respond_to?(:call) ? instance_exec(&value) : value)
        elsif opt.is_a?(Symbol)
          key = opt
          value = attrs.fetch(opt) { |k| raise KeyError, "NxtInit attr_init key :#{k} was missing at initialization!"}
        else
          raise InvalidOptionError, "Don't know how to deal with #{opt}"
        end
        instance_variable_set("@#{key}", value)
      end
    end

  end

  def self.included(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
  end
end