![Build Status](https://github.com/state-machines/state_machines-activemodel/actions/workflows/ruby.yml/badge.svg)
[![Code Climate](https://codeclimate.com/github/state-machines/state_machines-activemodel.svg)](https://codeclimate.com/github/state-machines/state_machines-activemodel)

# StateMachines ActiveModel Integration

The ActiveModel integration is useful for both standalone usage and for providing
the base implementation for ORMs which implement the ActiveModel API.  This
integration adds support for validation errors and dirty attribute tracking.

## Installation

Add this line to your application's Gemfile:

    gem 'state_machines-activemodel'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install state_machines-activemodel

## Dependencies

Active Model 7.1+

## Usage

```ruby

class Vehicle
  include ActiveModel::Dirty
  include ActiveModel::Validations

  attr_accessor :state
  define_attribute_methods [:state]

  state_machine initial: :parked do
    before_transition parked: any - :parked, do: :put_on_seatbelt
    after_transition any: :parked do |vehicle, transition|
      vehicle.seatbelt = 'off'
    end
    around_transition :benchmark

    event ignite: do
      transition parked: :idling
    end

    state :first_gear, :second_gear do
      validates :seatbelt_on, presence: true
    end
  end

  def put_on_seatbelt
    ...
  end

  def benchmark
    ...
    yield
    ...
  end
end
```

## Contributing

1. Fork it ( https://github.com/state-machines/state_machines-activemodel/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
