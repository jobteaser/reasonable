# Reasonable::Value

Reasonable::Value is a value object implementation in its smallest possible
form.

## Why another implementation ?

### Virtus
  [Virtus](https://github.com/solnic/virtus) does too many things and is
  deprecated in favor of [dry-struct](https://github.com/dry-rb/dry-struct)

### dry-struct
I felt that [dry-struct](https://github.com/dry-rb/dry-struct) was
1. Not documented enough
2. Did not properly handle "truly" optional attributes

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'reasonable-value'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install reasonable-value

## Usage

By default attributes are mandatory, but corcible (meaning that passing a Float
when an Integer is expected will **not** raise an error:
``` ruby
class StandardValue < Reasonable::Value
  attribute :integer, Integer
end

p StandardValue.new
# => TypeError: expected :integer to be a Integer but was a NilClass

p StandardValue.new(integer: nil)
# => TypeError: expected :integer to be a Integer but was a NilClass

p StandardValue.new(integer: 1)
# => #<StandardValue:0x007f65ec156720 @attributes={:integer=>1}>

p StandardValue.new(integer: 1.1)
# => #<StandardValue:0x007f65ec166738 @attributes={:integer=>1}>
```

If you want optional attributes, you can say so like that:
``` ruby
class OptionalValue < Reasonable::Value
  attribute :string, String, optional: true
end

p OptionalValue.new
# => #<OptionalValue:0x0055ecec2ae2c8 @attributes={}>

p OptionalValue.new(string: nil)
# => #<OptionalValue:0x007f65ec16c430 @attributes={}>

p OptionalValue.new(string: 'string')
# => #<OptionalValue:0x007f65ec174f18 @attributes={:string=>"string"}>

p OptionalValue.new(string: 1.1)
# => #<OptionalValue:0x007f65ec1792e8 @attributes={:string=>"1.1"}>
```

You are not limited to Integer or String, you can use any type you want:
``` ruby
class ValueWithCustomType < Reasonable::Value
  attribute :custom, StandardValue
end

p ValueWithCustomType.new(custom: StandardValue.new(integer: 1))
# => #<ValueWithCustomType:0x007f65ec18d540 @attributes={:custom=>#<StandardValue:0x007f65ec18d6a8 @attributes={:integer=>1}>}>

p ValueWithCustomType.new(custom: { integer: 1 })
# => #<ValueWithCustomType:0x007f65ec19f920 @attributes={:custom=>#<StandardValue:0x007f65ec19f358 @attributes={:integer=>1}>}>
```

You can pass a list of types if need be:
``` ruby
class TypeListValue < Reasonable::Value
  attribute :boolean, [TrueClass, FalseClass]
end

p TypeListValue.new(boolean: true)
# => #<TypeListValue:0x00560d002c7f50 @attributes={:boolean=>true}>
p TypeListValue.new(boolean: false)
# => #<TypeListValue:0x00560d002c7f50 @attributes={:boolean=>false}>
p TypeListValue.new(boolean: 'error')
# => TypeError: expected :boolean to be a [TrueClass, FalseClass] but was a String
```

If you define the appropriate method on the class of the attribute,
Reasonable::Value will handle casting gracefully:
``` ruby
class CastableType
  def to_standard_value
    StandardValue.new(integer: 1)
  end
end

p StandardValue.new(CastableType.new)
# => #<StandardValue:0x005598945ba928 @attributes={:integer=>1}>

p ValueWithCustomType.new(custom: CastableType.new)
# => #<ValueWithCustomType:0x007f65ec1a6590 @attributes={:custom=>#<StandardValue:0x007f65ec1a5bb8 @attributes={:integer=>1}>}>
```

Equality is based on attributes, instead of identity:

``` ruby
p StandardValue.new(integer: 1) == StandardValue.new(integer: 1)
# => true
p StandardValue.new(integer: 1) == StandardValue.new(integer: 2)
# => false
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/reasonable-value.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
