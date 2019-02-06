# Attrinit

Create an initializer that accepts option arguments and define private readers for your 
arguments at the same time. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'attrinit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install attrinit

## Usage

```ruby
class MyService
    include Attrinit
    attr_initializer :one, 
             two: 'has a default', 
             three: nil, # makes the attribute optional
             four: -> { "This is set on initialize: #{Time.now} - means it will not be evaluated multiple times" } 
             
    def call
      {
        one: one,
        two: two,
        three: three,
        four: four
      }
    end
end

my_service = MyService.new(one: 'this is required')
my_service.call

# Will output the following:
{

  one: "this is required", 
  two: "has a default", 
  three: nil, 
  four: "This is evaluated on initialize: 2019-02-04 18:10:56 +0100 - means it will not be evaluated multiple times"
} 
```

The attribute readers are private. If you need public accessors you have to add them yourself. That's all there is.
Check out the specs for examples how we handle inheritance. 

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nxt-insurance/attrinit.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
