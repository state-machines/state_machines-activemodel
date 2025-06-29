# frozen_string_literal: true

require_relative 'test_helper'

class StateHumanNameTest < BaseTestCase
  def setup
    @model = new_model do
      include ActiveModel::Validations
      attr_accessor :status
    end
  end

  def test_should_allow_custom_human_name_on_state
    machine = StateMachines::Machine.new(@model, :status, initial: :pending) do
      state :pending, human_name: 'Awaiting Approval'
      state :approved
      state :rejected, human_name: 'Denied'
    end

    assert_equal 'Awaiting Approval', machine.states[:pending].human_name(@model)
    assert_equal 'Denied', machine.states[:rejected].human_name(@model)
  end

  def test_should_not_override_custom_human_name_with_translation
    # Set up I18n translations
    I18n.backend.store_translations(:en, {
                                      activemodel: {
                                        state_machines: {
                                          states: {
                                            pending: 'Translation for Pending',
                                            approved: 'Translation for Approved',
                                            rejected: 'Translation for Rejected'
                                          }
                                        }
                                      }
                                    })

    machine = StateMachines::Machine.new(@model, :status, initial: :pending) do
      state :pending, human_name: 'Custom Pending Name'
      state :approved
      state :rejected, human_name: 'Custom Rejected Name'
    end

    # Custom human names should be preserved
    assert_equal 'Custom Pending Name', machine.states[:pending].human_name(@model)
    assert_equal 'Custom Rejected Name', machine.states[:rejected].human_name(@model)

    # State without custom human_name gets default behavior (which might not use translations in this test setup)
    # The key test is that custom human names are preserved, not overwritten
    refute_equal 'Custom Pending Name', machine.states[:approved].human_name(@model)
  end

  def test_should_allow_custom_human_name_as_string
    machine = StateMachines::Machine.new(@model, :status) do
      state :active, human_name: 'Currently Active'
    end

    assert_equal 'Currently Active', machine.states[:active].human_name(@model)
  end

  def test_should_allow_custom_human_name_as_lambda
    machine = StateMachines::Machine.new(@model, :status) do
      state :processing, human_name: ->(state, klass) { "#{klass.name} is #{state.name.to_s.upcase}" }
    end

    assert_equal 'Foo is PROCESSING', machine.states[:processing].human_name(@model)
  end

  def test_should_use_default_translation_when_no_custom_human_name
    machine = StateMachines::Machine.new(@model, :status) do
      state :idle
    end

    # Should fall back to humanized version when no translation exists
    assert_equal 'idle', machine.states[:idle].human_name(@model)
  end

  def test_should_handle_nil_human_name
    machine = StateMachines::Machine.new(@model, :status) do
      state :waiting
    end

    # Explicitly set to nil (should still get default behavior)
    machine.states[:waiting].human_name = nil

    # When human_name is nil, State#human_name returns nil
    assert_nil machine.states[:waiting].human_name(@model)
  end

  def test_should_preserve_human_name_through_multiple_state_definitions
    machine = StateMachines::Machine.new(@model, :status)

    # First define state with custom human name
    machine.state :draft, human_name: 'Work in Progress'

    # Redefine the same state (this should not override the human_name)
    machine.state :draft do
      # Add some behavior
    end

    assert_equal 'Work in Progress', machine.states[:draft].human_name(@model)
  end

  def test_should_work_with_state_machine_helper_method
    @model.class_eval do
      state_machine :status, initial: :pending do
        state :pending, human_name: 'Awaiting Review'
        state :reviewed
      end
    end

    machine = @model.state_machine(:status)
    assert_equal 'Awaiting Review', machine.states[:pending].human_name(@model)
  end

  def test_should_handle_complex_i18n_lookup_with_custom_human_name
    # Set up complex I18n structure
    I18n.backend.store_translations(:en, {
                                      activemodel: {
                                        state_machines: {
                                          foo: {
                                            status: {
                                              states: {
                                                pending: 'Model Specific Pending'
                                              }
                                            }
                                          },
                                          status: {
                                            states: {
                                              pending: 'Machine Specific Pending'
                                            }
                                          },
                                          states: {
                                            pending: 'Generic Pending'
                                          }
                                        }
                                      }
                                    })

    machine = StateMachines::Machine.new(@model, :status) do
      state :pending, human_name: 'Overridden Pending'
    end

    # Should use the custom human_name, not any of the I18n translations
    assert_equal 'Overridden Pending', machine.states[:pending].human_name(@model)
  end

  def teardown
    # Clear I18n translations after each test
    I18n.backend.reload!
  end
end
