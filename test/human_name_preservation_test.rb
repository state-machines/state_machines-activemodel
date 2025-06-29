# frozen_string_literal: true

require_relative 'test_helper'

class HumanNamePreservationTest < BaseTestCase
  def setup
    @model = new_model do
      include ActiveModel::Validations
      attr_accessor :status
    end
  end

  def test_should_preserve_custom_state_human_name_when_using_activemodel_integration
    # This test specifically verifies that PR #38's fix works:
    # Using ||= instead of = in add_states method

    @model.class_eval do
      state_machine :status, initial: :pending do
        # Define a state with a custom human_name
        state :pending, human_name: 'My Custom Pending'
        state :approved
      end
    end

    machine = @model.state_machine(:status)

    # The custom human_name should be preserved, not overwritten by the integration
    assert_equal 'My Custom Pending', machine.states[:pending].human_name(@model)
  end

  def test_should_preserve_custom_event_human_name_when_using_activemodel_integration
    # This test verifies our additional fix for events:
    # Using ||= instead of = in add_events method

    @model.class_eval do
      state_machine :status, initial: :pending do
        event :approve, human_name: 'Grant Authorization' do
          transition pending: :approved
        end

        event :reject do
          transition pending: :rejected
        end
      end
    end

    machine = @model.state_machine(:status)

    # The custom human_name should be preserved, not overwritten by the integration
    assert_equal 'Grant Authorization', machine.events[:approve].human_name(@model)
  end

  def test_regression_issue_37_hard_coded_human_name_preserved
    # This is the exact regression test for issue #37
    # "Hard-coded human_name is being overwritten"

    @model.class_eval do
      state_machine :status do
        state :pending, human_name: 'Pending Approval'
        state :active, human_name: 'Active State'

        event :activate, human_name: 'Activate Now' do
          transition pending: :active
        end
      end
    end

    machine = @model.state_machine(:status)

    # Both states and events should preserve their hard-coded human names
    assert_equal 'Pending Approval', machine.states[:pending].human_name(@model)
    assert_equal 'Active State', machine.states[:active].human_name(@model)
    assert_equal 'Activate Now', machine.events[:activate].human_name(@model)
  end
end
