# frozen_string_literal: true

require 'test_helper'

class MachineWithModelStateAttributeTest < BaseTestCase
  def setup
    @model = new_model
    @machine = StateMachines::Machine.new(@model, initial: :parked, integration: :active_model)
    @machine.other_states(:idling)

    @record = @model.new
  end

  def test_should_have_an_attribute_predicate
    assert @record.respond_to?(:state?)
  end

  def test_should_raise_exception_for_predicate_without_parameters
    assert_raises(ArgumentError) { @record.state? }
  end

  def test_should_return_false_for_predicate_if_does_not_match_current_value
    assert !@record.state?(:idling)
  end

  def test_should_return_true_for_predicate_if_matches_current_value
    assert @record.state?(:parked)
  end

  def test_should_raise_exception_for_predicate_if_invalid_state_specified
    assert_raises(IndexError) { @record.state?(:invalid) }
  end
end
