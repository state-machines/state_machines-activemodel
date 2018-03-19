require_relative 'test_helper'

class MachineWithDirtyAttributesTest < BaseTestCase
  def setup
    @model = new_model do
      include ActiveModel::Dirty
      define_attribute_methods [:state]

      def save
        super.tap do
          changes_applied
        end
      end
    end
    @machine = StateMachines::Machine.new(@model, initial: :parked)
    @machine.event :ignite
    @machine.state :idling

    @record = @model.create

    @transition = StateMachines::Transition.new(@record, @machine, :ignite, :parked, :idling)
    @transition.perform
  end

  def test_should_include_state_in_changed_attributes
    assert_equal %w(state), @record.changed
  end

  def test_should_track_attribute_change
    assert_equal %w(parked idling), @record.changes['state']
  end

  def test_should_not_reset_changes_on_multiple_transitions
    transition = StateMachines::Transition.new(@record, @machine, :ignite, :idling, :idling)
    transition.perform

    assert_equal %w(parked idling), @record.changes['state']
  end
end
