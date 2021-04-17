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

Active Model 5.1+

## Usage

```ruby

class Vehicle
  include ActiveModel::Dirty
  include ActiveModel::Validations

  attr_accessor :state
  define_attribute_methods [:state]

  state_machine :initial => :parked do
    before_transition :parked => any - :parked, :do => :put_on_seatbelt
    after_transition any => :parked do |vehicle, transition|
      vehicle.seatbelt = 'off'
    end
    around_transition :benchmark

    event :ignite do
      transition :parked => :idling
    end

    state :first_gear, :second_gear do
      validates_presence_of :seatbelt_on
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

class VehicleObserver < ActiveModel::Observer
  # Callback for :ignite event *before* the transition is performed
  def before_ignite(vehicle, transition)
    # log message
  end

  # Generic transition callback *after* the transition is performed
  def after_transition(vehicle, transition)
    Audit.log(vehicle, transition)
  end

  # Generic callback after the transition fails to perform
  def after_failure_to_transition(vehicle, transition)
    Audit.error(vehicle, transition)
  end
end

```

## Contributing

1. Fork it ( https://github.com/state-machines/state_machines-activemodel/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
