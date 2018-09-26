# frozen_string_literal: true

require 'reasonable/value/version'
require 'active_support/core_ext/string/inflections'

module Reasonable
  class Value

    include Comparable
    def <=>(other)
      @attributes <=> other.instance_variable_get(:@attributes)
    end

    def initialize(attributes = {})
      @attributes = {}

      self.class.send(:config).each do |name, config|
        options = config[:options]
        if options[:optional]
          attributes[name] = options[:default] if attributes[name].nil?
          next if attributes[name].nil?
        end

        type_error(name, config[:type], NilClass) if attributes[name].nil?

        @attributes[name] = coerce(attributes, name, config)
      end
    end

    def to_hash
      @attributes
    end

    class << self

      def new(object = {})
        Try.(MethodName.(self), object) || super(object)
      end

      def inherited(subklass)
        config.each do |name, config|
          subklass.attribute(name, config[:type], options: config[:options])
        end
      end

      protected

      def attribute(name, type, **options)
        mutex.synchronize { config[name] = { type: type, options: options } }

        define_method(name) { @attributes[name] }
      end

      private

      def mutex
        return @mutex if defined?(@mutex)

        @mutex = Thread::Mutex.new
      end

      def config
        return @config if defined?(@config)

        @config = {}
      end

    end

    private

    def coerce(attributes, name, config)
      Coercer.(config[:type], attributes[name])
    rescue TypeError
      type_error(name, config[:type], attributes[name].class)
    end

    def type_error(name, expected, actual)
      raise(
        TypeError,
        "expected :#{name} to be a #{expected} but was a #{actual}"
      )
    end

    class Coercer

      class << self

        def call(types, value)
          coerced = Array(types).reduce(nil) do |memo, type|
            memo || built_in(type, value) || custom(type, value)
          end

          coerced.nil? and raise(TypeError) or coerced
        end

        private

        def built_in(type, value)
          return unless Kernel.respond_to?(type.to_s)

          Kernel.public_send(type.to_s, value)
        rescue ArgumentError, TypeError
          nil
        end

        def custom(type, value)
          return value if value.is_a?(type)

          Try.(MethodName.(type), value) || reasonable(type, value)
        end

        def reasonable(type, value)
          return unless type.ancestors.include?(Reasonable::Value)
          return unless value.is_a?(Hash)

          type.new(value)
        end

      end

    end
    private_constant :Coercer

    module Try
      def self.call(method_name, object)
        object.public_send(method_name) if object.respond_to?(method_name)
      end
    end
    private_constant :Try

    module MethodName
      def self.call(klass)
        "to_#{klass.to_s.split('::').last.underscore}"
      end
    end
    private_constant :MethodName

  end
end
