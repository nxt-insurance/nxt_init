# NxtInit

Create an initializer that accepts option arguments and define private readers for your 
arguments at the same time. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nxt_init'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nxt_init

## Usage

NxtInit removes some boilerplate. Instead of writing your initializer and (private) attribute readers each and every time like so:

```ruby
class GetSafe
  def initialize(frontend:, backend:)
    @frontend = frontend
    @backend = backend
  end
  
  private 
  
  attr_reader :frontend, :backend
end
```

You can instead do the following:

```ruby
class GetSafe
  include NxtInit
  attr_init :frontend, :backend
end
```

### Optional arguments and defaults

In order to provide default values you can simply use the hash syntax to define your defaults. 
If you want to make an attribute optional, just pass nil as the default argument. 
If there is no default value and you did not provide one when initializing your class, you will get a KeyError.

```ruby
class GetSafe
  include NxtInit
  attr_init frontend: 'React', 
            backend: -> { 'Ruby on Rails' }, 
            middleware: nil
end
```

### Preprocessors

If you want to preprocess your attribute somehow, you can define a preprocessor block to which the original attribute will be yielded.
Note that you can also call methods in your block if you have some heavier lifting to do.

```ruby
class GetSafe
  include NxtInit
  attr_init date: -> (date) { date && date.is_a?(Date) ? date : Date.parse(date) }
end
```

Also you can still pass in nil if your block can handle it. If the attribute is not provided on initialization again a KeyError will be raised. 

### Inheritance

When you inherit from a class that already includes NxtInit you can add further attributes to your subclass and overwrite existing options
simply by using attr_init for the same attributes. Check out the specs for more examples.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nxt-insurance/nxt_init.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
