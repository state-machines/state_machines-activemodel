require_relative 'test_helper'

class MachineWithStaticInitialStateTest < BaseTestCase
  def setup
    @model = new_model
    @machine = StateMachines::Machine.new(@model, initial: :parked, integration: :active_model)
  end

  def test_should_set_initial_state_on_created_object
    record = @model.new
    assert_equal 'parked', record.state
  end
end
