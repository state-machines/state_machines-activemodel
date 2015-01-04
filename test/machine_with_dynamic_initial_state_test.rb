require_relative 'test_helper'

class MachineWithDynamicInitialStateTest < BaseTestCase
  def setup
    @model = new_model
    @machine = StateMachines::Machine.new(@model, initial: lambda { |_object| :parked }, integration: :active_model)
    @machine.state :parked
  end

  def test_should_set_initial_state_on_created_object
    record = @model.new
    assert_equal 'parked', record.state
  end
end
