# frozen_string_literal: true

require 'reasonable/value/version'
require 'active_support/core_ext/string/inflections'

module Reasonable
  class Value

    include Comparable
    def <=>(other)
      @attributes <=> other.instance_variable_get(:@attributes)
    end

    def initialize(**attributes)
      @attributes = {}

      self.class.send(:config).each do |name, config|
        next if attributes[name].nil? && config[:options][:optional]

        @attributes[name] = coerce(attributes, name, config)
      end
    end

    class << self

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
        @config ||= {}
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
          raise TypeError unless type.ancestors.include?(Reasonable::Value)

          type.new(value)
        end

      end

    end
    private_constant :Coercer

  end
end
