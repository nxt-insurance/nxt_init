require "nxt_init/version"
require "nxt_init/option"
require "nxt_init/not_provided_option"
require 'active_support/all'

module NxtInit
  module ClassMethods
    def attr_init(*args)
      options_map = build_options_map(*args)

      self.attr_init_opts ||= {}
      self.attr_init_opts.merge!(options_map)

      define_private_readers(*options_map.keys)
    end

    attr_accessor :attr_init_opts

    private

    def inherited(subclass)
      subclass.attr_init_opts = attr_init_opts.deep_dup
    end

    def define_private_readers(*keys)
      attr_reader *keys
      private *keys
    end

    def build_options_map(*args)
      options_hash = *args.extract_options!
      options_from_args = args.each_with_object({}) { |key, acc| acc[key] = Option.new(key) }
      options_from_options = options_hash.each_with_object({}) { |(key, value), acc| acc[key] = Option.new(key, default_value: value) }
      options_from_args.merge(options_from_options)
    end
  end

  module InstanceMethods
    def initialize(*args, **attrs)
      option_keys = self.class.send(:attr_init_opts).keys

      attr_init_opts = attrs.slice(*option_keys)
      other_options = attrs.slice!(*option_keys)
      # passing **{} is like calling super({}) which does not work when super does not except arguments#
      initialize_attrs_from_options(**attr_init_opts)
      other_options.empty? ? super(*args) : super(*args, **other_options)
    end

    private

    def initialize_attrs_from_options(**attrs)
      self.class.send(:attr_init_opts).each do |_, opt|
        value = opt.resolve(attrs)
        instance_variable_set("@#{opt.key}", value)
      end
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
  end
end
