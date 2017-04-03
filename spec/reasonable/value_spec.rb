# frozen_string_literal: true

require 'spec_helper'

class StandardValue < Reasonable::Value

  attribute :integer, Integer

end

class TypeListValue < Reasonable::Value

  attribute :boolean, [TrueClass, FalseClass]

end

class InheritedStandardValue < StandardValue

  attribute :string, String

end

class DeeplyInheritedStandardValue < InheritedStandardValue

  attribute :integer, Float
  attribute :string, String, optional: true

end

class OptionalValue < Reasonable::Value

  attribute :integer, Integer, optional: true
  attribute :string, String, optional: true

end

class ValueWithCustomType < Reasonable::Value

  attribute :custom, StandardValue

end

class CastableType

  def to_standard_value
    StandardValue.new(integer: 1)
  end

end

RSpec.describe Reasonable::Value do
  it 'has a version number' do
    expect(Reasonable::Value::VERSION).not_to be nil
  end

  describe '.attribute' do
    it 'validates the type' do
      expect(StandardValue.new(integer: 1).integer).
        to eq(1)
      expect { StandardValue.new(integer: 'test').integer }.
        to raise_error(
          TypeError,
          'expected :integer to be a Integer but was a String'
        )
    end

    it 'coerces the values' do
      expect(OptionalValue.new(integer: 1.1).integer).
        to eq(1)
      expect(OptionalValue.new(string: 1).string).
        to eq('1')

      expect { OptionalValue.new(integer: Object.new).string }.
        to raise_error(
          TypeError,
          'expected :integer to be a Integer but was a Object'
        )
    end

    it 'requires the specified attribute to be present' do
      expect { StandardValue.new.integer }.
        to raise_error(
          TypeError,
          'expected :integer to be a Integer but was a NilClass'
        )
      expect { StandardValue.new(integer: nil).integer }.
        to raise_error(
          TypeError,
          'expected :integer to be a Integer but was a NilClass'
        )
    end

    it 'supports an "optional" parameter' do
      expect(OptionalValue.new.integer).
        to eq(nil)
      expect(OptionalValue.new(integer: nil).integer).
        to eq(nil)
    end

    it 'ignores undefined attributes' do
      expect { OptionalValue.new(undefined: 'undefined') }.
        not_to raise_error
      expect { OptionalValue.new(undefined: 'undefined').undefined }.
        to raise_error(NoMethodError)
    end

    it 'supports custom types' do
      standard = StandardValue.new(integer: -1)
      expect { ValueWithCustomType.new(custom: standard) }.
        not_to raise_error
      expect(ValueWithCustomType.new(custom: standard).custom).
        to eq(standard)
    end

    it 'compares based on propertise, not on identity' do
      expect(StandardValue.new(integer: 1)).
        to eq(StandardValue.new(integer: 1))

      expect(StandardValue.new(integer: 1)).
        not_to eq(StandardValue.new(integer: 2))
    end

    it 'handles nested hash parameter' do
      expect { ValueWithCustomType.new(custom: { integer: 1 }) }.
        not_to raise_error
      expect(ValueWithCustomType.new(custom: { integer: 1 }).custom).
        to eq(StandardValue.new(integer: 1))
    end

    it 'handles type casting' do
      expect { ValueWithCustomType.new(custom: CastableType.new) }.
        not_to raise_error
    end

    it 'supports inheritance' do
      value = InheritedStandardValue.new(integer: 1, string: 'string')

      expect(value.string).to eq('string')
      expect(value.integer).to eq(1)
    end

    it 'supports attribute definition overwrite through inheritance' do
      value = DeeplyInheritedStandardValue.new(integer: 1.1)
      expect(value.string).to be_nil
      expect(value.integer).to eq(1.1)
    end

    it 'handles type list' do
      expect { TypeListValue.new(boolean: true) }.
        not_to raise_error
      expect(TypeListValue.new(boolean: true).boolean).
        to eq(true)

      expect { TypeListValue.new(boolean: false) }.
        not_to raise_error
      expect(TypeListValue.new(boolean: false).boolean).
        to eq(false)

      expect { TypeListValue.new(boolean: 'error') }.
        to raise_error(
          TypeError,
          'expected :boolean to be a [TrueClass, FalseClass] but was a String'
        )
    end
  end
end
