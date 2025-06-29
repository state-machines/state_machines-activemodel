# frozen_string_literal: true

require_relative 'test_helper'

class EventHumanNameTest < BaseTestCase
  def setup
    @model = new_model do
      include ActiveModel::Validations
      attr_accessor :status
    end
  end

  def test_should_allow_custom_human_name_on_event
    machine = StateMachines::Machine.new(@model, :status, initial: :parked) do
      event :start, human_name: 'Start Engine' do
        transition parked: :running
      end

      event :stop do
        transition running: :parked
      end

      event :pause, human_name: 'Temporarily Pause' do
        transition running: :paused
      end
    end

    assert_equal 'Start Engine', machine.events[:start].human_name(@model)
    assert_equal 'Temporarily Pause', machine.events[:pause].human_name(@model)
  end

  def test_should_not_override_custom_event_human_name_with_translation
    # Set up I18n translations
    I18n.backend.store_translations(:en, {
                                      activemodel: {
                                        state_machines: {
                                          events: {
                                            ignite: 'Translation for Ignite',
                                            park: 'Translation for Park',
                                            repair: 'Translation for Repair'
                                          }
                                        }
                                      }
                                    })

    machine = StateMachines::Machine.new(@model, :status, initial: :parked) do
      event :ignite, human_name: 'Custom Ignition' do
        transition parked: :idling
      end

      event :park do
        transition idling: :parked
      end

      event :repair, human_name: 'Custom Repair Process' do
        transition any => :parked
      end
    end

    # Custom human names should be preserved
    assert_equal 'Custom Ignition', machine.events[:ignite].human_name(@model)
    assert_equal 'Custom Repair Process', machine.events[:repair].human_name(@model)

    # Event without custom human_name should use translation
    assert_equal 'Translation for Park', machine.events[:park].human_name(@model)
  end

  def test_should_allow_custom_event_human_name_as_string
    machine = StateMachines::Machine.new(@model, :status) do
      event :activate, human_name: 'Turn On'
    end

    assert_equal 'Turn On', machine.events[:activate].human_name(@model)
  end

  def test_should_allow_custom_event_human_name_as_lambda
    machine = StateMachines::Machine.new(@model, :status) do
      event :process, human_name: ->(event, klass) { "#{klass.name}: #{event.name.to_s.capitalize} Action" }
    end

    assert_equal 'Foo: Process Action', machine.events[:process].human_name(@model)
  end

  def test_should_use_default_translation_when_no_custom_event_human_name
    machine = StateMachines::Machine.new(@model, :status) do
      event :idle
    end

    # Should fall back to humanized version when no translation exists
    assert_equal 'idle', machine.events[:idle].human_name(@model)
  end

  def test_should_handle_nil_event_human_name
    machine = StateMachines::Machine.new(@model, :status) do
      event :wait
    end

    # Explicitly set to nil
    machine.events[:wait].human_name = nil

    # When human_name is nil, Event#human_name returns nil
    assert_nil machine.events[:wait].human_name(@model)
  end

  def test_should_preserve_event_human_name_through_multiple_definitions
    machine = StateMachines::Machine.new(@model, :status, initial: :draft)

    # First define event with custom human name
    machine.event :publish, human_name: 'Make Public' do
      transition draft: :published
    end

    # Redefine the same event (this should not override the human_name)
    machine.event :publish do
      transition pending: :published
    end

    assert_equal 'Make Public', machine.events[:publish].human_name(@model)
  end

  def test_should_work_with_state_machine_helper_method
    @model.class_eval do
      state_machine :status, initial: :pending do
        event :approve, human_name: 'Grant Approval' do
          transition pending: :approved
        end

        event :reject do
          transition pending: :rejected
        end
      end
    end

    machine = @model.state_machine(:status)
    assert_equal 'Grant Approval', machine.events[:approve].human_name(@model)
  end

  def test_should_handle_complex_i18n_lookup_with_custom_event_human_name
    # Set up complex I18n structure
    I18n.backend.store_translations(:en, {
                                      activemodel: {
                                        state_machines: {
                                          foo: {
                                            status: {
                                              events: {
                                                submit: 'Model Specific Submit'
                                              }
                                            }
                                          },
                                          status: {
                                            events: {
                                              submit: 'Machine Specific Submit'
                                            }
                                          },
                                          events: {
                                            submit: 'Generic Submit'
                                          }
                                        }
                                      }
                                    })

    machine = StateMachines::Machine.new(@model, :status) do
      event :submit, human_name: 'Send for Review' do
        transition draft: :pending
      end
    end

    # Should use the custom human_name, not any of the I18n translations
    assert_equal 'Send for Review', machine.events[:submit].human_name(@model)
  end

  def teardown
    # Clear I18n translations after each test
    I18n.backend.reload!
  end
end
