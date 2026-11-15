# frozen_string_literal: true

require 'test_helper'

class MachineWithRefusalReasonsTest < BaseTestCase
  def setup
    @model = new_model do
      include ActiveModel::Validations

      attribute :alarm_state, :string
      attr_accessor :fuelled, :abort_ignite, :jam_alarm, :saved

      validates :state, exclusion: { in: %w[blocked] }

      # Defined on an ancestor so the machine hooks it for event attributes
      include(Module.new do
        def save
          valid? && (self.saved = true)
        end
      end)
    end

    @machine = StateMachines::Machine.new(@model, action: :save, initial: :parked)
    @machine.state :blocked
    @machine.before_transition(on: :ignite) { |record| !record.abort_ignite }
    @machine.event(:ignite) { transition parked: :idling, if: ->(record) { record.fuelled != false } }
    @machine.event(:park) { transition idling: :parked }
    @machine.event(:block) { transition parked: :blocked }

    @alarm = StateMachines::Machine.new(@model, :alarm_state, action: :save, initial: :active, namespace: :alarm)
    @alarm.around_transition(on: :disable) do |record, _transition, block|
      block.call unless record.jam_alarm
    end
    @alarm.event(:disable) { transition active: :off }

    @record = @model.new
  end

  def test_should_report_no_transition
    assert_same false, @record.park
    assert_equal :no_transition, @record.park_refusal
  end

  def test_should_keep_the_invalid_transition_error
    @record.park

    assert_equal ['State cannot transition via "park"'], @record.errors.full_messages
  end

  def test_should_report_guard
    @record.fuelled = false

    refute @record.ignite
    assert_equal :guard, @record.ignite_refusal
  end

  def test_should_report_halted_by_a_before_transition_returning_false
    @record.abort_ignite = true

    refute @record.ignite
    assert_equal :halted, @record.ignite_refusal
    assert_equal 'parked', @record.state
  end

  def test_should_report_halted_by_an_around_transition_that_does_not_yield
    @record.jam_alarm = true

    refute @record.disable_alarm
    assert_equal :halted, @record.disable_alarm_refusal
  end

  def test_should_report_action_failed_when_validation_fails
    refute @record.block
    assert_equal :action_failed, @record.block_refusal
    assert_equal 'parked', @record.state
    refute @record.saved
  end

  def test_should_keep_validation_errors_when_the_action_fails
    @record.block

    assert_equal ['State is reserved'], @record.errors.full_messages
  end

  def test_should_clear_the_refusal_after_success
    @record.abort_ignite = true
    @record.ignite
    @record.abort_ignite = false

    assert @record.ignite
    assert_nil @record.ignite_refusal
    assert @record.saved
  end

  def test_should_carry_the_reason_on_bang
    error = assert_raises(StateMachines::InvalidTransition) { @record.block! }

    assert_equal :action_failed, error.reason
    assert_includes error.message, 'State is reserved'
  end

  def test_should_carry_halted_on_bang
    @record.abort_ignite = true
    error = assert_raises(StateMachines::InvalidTransition) { @record.ignite! }

    assert_equal :halted, error.reason
    assert_includes error.message, 'Transition halted'
  end

  def test_should_report_no_transition_for_an_event_attribute
    @record.state_event = 'park'

    refute @record.save
    assert_equal :no_transition, @record.park_refusal
  end

  def test_should_report_action_failed_for_an_event_attribute
    @record.state_event = 'block'

    refute @record.save
    assert_equal :action_failed, @record.block_refusal
  end

  def test_should_report_action_failed_for_every_event_in_parallel
    @record.fuelled = true
    @record.define_singleton_method(:save) { false }

    refute @record.fire_events(:ignite, :disable_alarm)
    assert_equal :action_failed, @record.ignite_refusal
    assert_equal :action_failed, @record.disable_alarm_refusal
  end

  def test_should_report_only_the_halting_event_in_parallel
    @record.jam_alarm = true

    refute @record.fire_events(:ignite, :disable_alarm)
    assert_nil @record.ignite_refusal
    assert_equal :halted, @record.disable_alarm_refusal
  end

  def test_should_carry_parallel_reasons_on_bang
    error = assert_raises(StateMachines::InvalidParallelTransition) { @record.fire_events!(:park, :disable_alarm) }

    assert_equal({ park: :no_transition }, error.reasons)
  end
end
