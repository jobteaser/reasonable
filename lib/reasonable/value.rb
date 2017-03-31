# frozen_string_literal: true

require 'reasonable/value/version'
require 'active_support/core_ext/string/inflections'

module Reasonable
  module Value
    def self.included(klass)
      klass.class_variable_set(:@@config, {})

      klass.extend(ClassMethods)
      klass.include(InstanceMethods)

      klass.class_eval do
        include Comparable

        def <=>(other)
          @attributes <=> other.instance_variable_get(:@attributes)
        end
      end
    end

    module InstanceMethods
      def initialize(**attributes)
        @attributes = {}

        self.class.class_variable_get(:@@config).each do |name, config|
          next if attributes[name].nil? && config[:options][:optional]

          @attributes[name] = coerce(attributes, name, config)
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
    end

    module ClassMethods
      def attribute(name, type, **options)
        class_variable_get(:@@config)[name] = { type: type, options: options }

        define_method(name) do
          @attributes[name]
        end
      end
    end

    class Coercer

      class << self

        def call(type, value)
          built_in(type, value) || custom(type, value)
        end

        private

        def built_in(type, value)
          return unless Kernel.respond_to?(type.to_s)

          Kernel.public_send(type.to_s, value)
        end

        def custom(type, value)
          return value if value.is_a?(type)

          if value.respond_to?("to_#{type.to_s.underscore}")
            return value.public_send("to_#{type.to_s.underscore}")
          end

          raise TypeError unless value.is_a?(Hash)
          raise TypeError unless type.include?(Reasonable::Value)

          type.new(value)
        end

      end

    end
    private_constant :Coercer
  end
end
