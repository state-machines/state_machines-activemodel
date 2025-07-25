# frozen_string_literal: true

require_relative 'test_helper'

class MachineInitializationCompatibilityTest < BaseTestCase
  def setup
    @model = new_model do
      include ActiveModel::Validations
    end

    @machine = StateMachines::Machine.new(@model, initial: :parked)
    @machine.state :parked, :idling
    @machine.event :ignite
  end

  def test_should_accept_positional_hash_argument
    record = @model.new({ state: 'idling' })
    assert_equal 'idling', record.state
  end

  def test_should_accept_keyword_arguments
    record = @model.new(state: 'idling')
    assert_equal 'idling', record.state
  end

  def test_should_accept_empty_initialization
    record = @model.new
    assert_equal 'parked', record.state
  end

  def test_should_handle_attribute_aliases
    @model.class_eval do
      alias_attribute :status, :state
    end

    record = @model.new(status: 'idling')
    assert_equal 'idling', record.state
  end

  def test_should_prefer_positional_hash_over_keywords_when_both_present
    # If someone accidentally provides both, positional takes precedence
    record = @model.new({ state: 'idling' }, state: 'parked')
    assert_equal 'idling', record.state
  end

  def test_should_handle_empty_positional_hash
    # Empty hash should still be treated as positional argument
    record = @model.new({})
    assert_equal 'parked', record.state # Gets default initial state
  end

  def test_should_use_keywords_when_empty_hash_and_keywords_present
    # With the fix, keywords are ignored even with empty positional hash
    record = @model.new({}, state: 'idling')
    assert_equal 'parked', record.state # Empty hash takes precedence
  end
end
