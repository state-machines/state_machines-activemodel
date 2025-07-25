# frozen_string_literal: true

require 'test_helper'

class MachineWithDirtyAttributesDuringLoopbackTest < BaseTestCase
  def setup
    @model = new_model do
      def save
        if valid?
          changes_applied
          true
        else
          false
        end
      end
    end
    @machine = StateMachines::Machine.new(@model, initial: :parked)
    @machine.event :park

    @record = @model.create

    @transition = StateMachines::Transition.new(@record, @machine, :park, :parked, :parked)
    @transition.perform
  end

  def test_should_not_include_state_in_changed_attributes
    assert_equal [], @record.changed
  end

  def test_should_not_track_attribute_changes
    assert_nil @record.changes['state']
  end
end
