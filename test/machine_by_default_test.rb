require_relative 'test_helper'

class MachineByDefaultTest < BaseTestCase
  def setup
    @model = new_model
    @machine = StateMachines::Machine.new(@model, integration: :active_model)
  end

  def test_should_not_have_action
    assert_nil @machine.action
  end

  def test_should_use_transactions
    assert_equal true, @machine.use_transactions
  end

  def test_should_not_have_any_before_callbacks
    assert_equal 0, @machine.callbacks[:before].size
  end

  def test_should_not_have_any_after_callbacks
    assert_equal 0, @machine.callbacks[:after].size
  end
end
