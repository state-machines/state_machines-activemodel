require_relative 'test_helper'

class MachineWithInitializedAliasedAttributeTest < BaseTestCase
  def test_should_match_original_attribute_value_with_attribute_methods
    model = new_model do
      include ActiveModel::AttributeMethods
      alias_attribute :custom_status, :state
    end

    machine = StateMachines::Machine.new(model, initial: :parked, integration: :active_model)
    machine.other_states(:started)

    record = model.new(custom_status: 'started')

    refute record.state?(:parked)
    assert record.state?(:started)
  end

  def test_should_not_match_original_attribute_value_without_attribute_methods
    model = new_model do
      alias_attribute :custom_status, :state
    end

    machine = StateMachines::Machine.new(model, initial: :parked, integration: :active_model)
    machine.other_states(:started)

    record = model.new(custom_status: 'started')

    assert record.state?(:parked)
    refute record.state?(:started)
  end
end

