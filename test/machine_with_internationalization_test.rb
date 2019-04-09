require_relative 'test_helper'
require 'i18n'

class MachineWithInternationalizationTest < BaseTestCase
  def setup
    I18n.backend = I18n::Backend::Simple.new
    @model = new_model { include ActiveModel::Validations }
  end

  def test_should_use_defaults
    I18n.backend.store_translations(:en,
                                    activemodel: { errors: { messages: { invalid_transition: 'cannot %{event}' } } }
                                    )

    machine = StateMachines::Machine.new(@model, action: :save)
    machine.state :parked, :idling
    machine.event :ignite

    record = @model.new(state: 'idling')

    machine.invalidate(record, :state, :invalid_transition, [[:event, 'ignite']])
    assert_equal ['State cannot transition via "ignite"'], record.errors.full_messages
  end

  def test_should_allow_customized_error_key
    I18n.backend.store_translations(:en,
                                    activemodel: { errors: { messages: { bad_transition: 'cannot %{event}' } } }
                                    )

    machine = StateMachines::Machine.new(@model, action: :save, messages: { invalid_transition: :bad_transition })
    machine.state :parked, :idling

    record = @model.new
    record.state = 'idling'

    machine.invalidate(record, :state, :invalid_transition, [[:event, 'ignite']])
    assert_equal ['State cannot ignite'], record.errors.full_messages
  end

  def test_should_allow_customized_error_string
    machine = StateMachines::Machine.new(@model, action: :save, messages: { invalid_transition: 'cannot %{event}' })
    machine.state :parked, :idling

    record = @model.new(state: 'idling')

    machine.invalidate(record, :state, :invalid_transition, [[:event, 'ignite']])
    assert_equal ['State cannot ignite'], record.errors.full_messages
  end

  def test_should_allow_customized_state_key_scoped_to_class_and_machine
    I18n.backend.store_translations(:en,
                                    activemodel: { state_machines: { :'foo' => { state: { states: { parked: 'shutdown' } } } } }
                                    )

    machine = StateMachines::Machine.new(@model)
    machine.state :parked
    assert_equal 'shutdown', machine.state(:parked).human_name
  end

  def test_should_allow_customized_state_key_scoped_to_class
    I18n.backend.store_translations(:en,
                                    activemodel: { state_machines: { :'foo' => { states: { parked: 'shutdown' } } } }
                                    )

    machine = StateMachines::Machine.new(@model)
    machine.state :parked

    assert_equal 'shutdown', machine.state(:parked).human_name
  end

  def test_should_allow_customized_state_key_scoped_to_machine
    I18n.backend.store_translations(:en,
                                    activemodel: { state_machines: { state: { states: { parked: 'shutdown' } } } }
                                    )

    machine = StateMachines::Machine.new(@model)
    machine.state :parked

    assert_equal 'shutdown', machine.state(:parked).human_name
  end

  def test_should_allow_customized_state_key_unscoped
    I18n.backend.store_translations(:en,
                                    activemodel: { state_machines: { states: { parked: 'shutdown' } } }
                                    )

    machine = StateMachines::Machine.new(@model)
    machine.state :parked

    assert_equal 'shutdown', machine.state(:parked).human_name
  end

  def test_should_support_nil_state_key
    I18n.backend.store_translations(:en,
                                    activemodel: { state_machines: { states: { nil: 'empty' } } }
                                    )

    machine = StateMachines::Machine.new(@model)

    assert_equal 'empty', machine.state(nil).human_name
  end

  def test_should_allow_customized_event_key_scoped_to_class_and_machine
    I18n.backend.store_translations(:en,
                                    activemodel: { state_machines: { :'foo' => { state: { events: { park: 'stop' } } } } }
                                    )

    machine = StateMachines::Machine.new(@model)
    machine.event :park

    assert_equal 'stop', machine.event(:park).human_name
  end

  def test_should_allow_customized_event_key_scoped_to_class
    I18n.backend.store_translations(:en,
                                    activemodel: { state_machines: { :'foo' => { events: { park: 'stop' } } } }
                                    )

    machine = StateMachines::Machine.new(@model)
    machine.event :park

    assert_equal 'stop', machine.event(:park).human_name
  end

  def test_should_allow_customized_event_key_scoped_to_machine
    I18n.backend.store_translations(:en,
                                    activemodel: { state_machines: { state: { events: { park: 'stop' } } } }
                                    )

    machine = StateMachines::Machine.new(@model)
    machine.event :park

    assert_equal 'stop', machine.event(:park).human_name
  end

  def test_should_allow_customized_event_key_unscoped
    I18n.backend.store_translations(:en,
                                    activemodel: { state_machines: { events: { park: 'stop' } } }
                                    )

    machine = StateMachines::Machine.new(@model)
    machine.event :park

    assert_equal 'stop', machine.event(:park).human_name
  end

  def test_should_have_locale_once_in_load_path
    assert_equal 1, I18n.load_path.select { |path| path =~ %r{active_model/locale\.rb$} }.length
  end

  def test_should_prefer_other_locales_first
    @original_load_path = I18n.load_path
    I18n.backend = I18n::Backend::Simple.new
    I18n.load_path = [File.dirname(__FILE__) + '/files/en.yml']

    machine = StateMachines::Machine.new(@model)
    machine.state :parked, :idling
    machine.event :ignite

    record = @model.new(state: 'idling')

    machine.invalidate(record, :state, :invalid_transition, [[:event, 'ignite']])
    assert_equal ['State cannot ignite'], record.errors.full_messages
  ensure
    I18n.load_path = @original_load_path
  end
end
