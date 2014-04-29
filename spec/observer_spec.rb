if ActiveModel::VERSION::MAJOR >= 4
  begin
    require 'rails/observers/active_model'
      # require 'active_model/mass_assignment_security'
  rescue LoadError
  end
else
  require 'active_model/observing'
end
require 'active_support/all'

if defined?(ActiveModel::Observing)

  context 'ObserverUpdate' do
    before(:each) do
      @model = new_model { include ActiveModel::Observing }
      @machine = StateMachines::Machine.new(@model)
      @machine.state :parked, :idling
      @machine.event :ignite

      @record = @model.new(:state => 'parked')
      @transition = StateMachines::Transition.new(@record, @machine, :ignite, :parked, :idling)

      @observer_update = StateMachines::Integrations::ActiveModel::ObserverUpdate.new(:before_transition, @record, @transition)
    end

    it 'should_have_method' do
      assert_equal :before_transition, @observer_update.method
    end

    it 'should_have_object' do
      assert_equal @record, @observer_update.object
    end

    it 'should_have_transition' do
      assert_equal @transition, @observer_update.transition
    end

    it 'should_include_object_and_transition_in_args' do
      assert_equal [@record, @transition], @observer_update.args
    end

    it 'should_use_record_class_as_class' do
      assert_equal @model, @observer_update.class
    end
  end

  context 'WithObservers' do
    before(:each) do
      @model = new_model { include ActiveModel::Observing }
      @machine = StateMachines::Machine.new(@model)
      @machine.state :parked, :idling
      @machine.event :ignite
      @record = @model.new(:state => 'parked')
      @transition = StateMachines::Transition.new(@record, @machine, :ignite, :parked, :idling)
    end

    it 'should_call_all_transition_callback_permutations' do
      callbacks = [
          :before_ignite_from_parked_to_idling,
          :before_ignite_from_parked,
          :before_ignite_to_idling,
          :before_ignite,
          :before_transition_state_from_parked_to_idling,
          :before_transition_state_from_parked,
          :before_transition_state_to_idling,
          :before_transition_state,
          :before_transition
      ]

      observer = new_observer(@model) do
        callbacks.each do |callback|
          define_method(callback) do |*args|
            notifications << callback
          end
        end
      end

      instance = observer.instance

      @transition.perform
      assert_equal callbacks, instance.notifications
    end

    it 'should_call_no_transition_callbacks_when_observers_disabled' do
      callbacks = [
          :before_ignite,
          :before_transition
      ]

      observer = new_observer(@model) do
        callbacks.each do |callback|
          define_method(callback) do |*args|
            notifications << callback
          end
        end
      end

      instance = observer.instance

      @model.observers.disable(observer) do
        @transition.perform
      end

      assert_equal [], instance.notifications
    end

    it 'should_pass_record_and_transition_to_before_callbacks' do
      observer = new_observer(@model) do
        def before_transition(*args)
          notifications << args
        end
      end
      instance = observer.instance

      @transition.perform
      assert_equal [[@record, @transition]], instance.notifications
    end

    it 'should_pass_record_and_transition_to_after_callbacks' do
      observer = new_observer(@model) do
        def after_transition(*args)
          notifications << args
        end
      end
      instance = observer.instance

      @transition.perform
      assert_equal [[@record, @transition]], instance.notifications
    end

    it 'should_call_methods_outside_the_context_of_the_record' do
      observer = new_observer(@model) do
        def before_ignite(*args)
          notifications << self
        end
      end
      instance = observer.instance

      @transition.perform
      assert_equal [instance], instance.notifications
    end

    it 'should_support_nil_from_states' do
      callbacks = [
          :before_ignite_from_nil_to_idling,
          :before_ignite_from_nil,
          :before_transition_state_from_nil_to_idling,
          :before_transition_state_from_nil
      ]

      observer = new_observer(@model) do
        callbacks.each do |callback|
          define_method(callback) do |*args|
            notifications << callback
          end
        end
      end

      instance = observer.instance

      transition = StateMachines::Transition.new(@record, @machine, :ignite, nil, :idling)
      transition.perform
      assert_equal callbacks, instance.notifications
    end

    it 'should_support_nil_to_states' do
      callbacks = [
          :before_ignite_from_parked_to_nil,
          :before_ignite_to_nil,
          :before_transition_state_from_parked_to_nil,
          :before_transition_state_to_nil
      ]

      observer = new_observer(@model) do
        callbacks.each do |callback|
          define_method(callback) do |*args|
            notifications << callback
          end
        end
      end

      instance = observer.instance

      transition = StateMachines::Transition.new(@record, @machine, :ignite, :parked, nil)
      transition.perform
      assert_equal callbacks, instance.notifications
    end
  end

  context 'WithNamespacedObservers' do
    before(:each) do
      @model = new_model { include ActiveModel::Observing }
      @machine = StateMachines::Machine.new(@model, :state, :namespace => 'alarm')
      @machine.state :active, :off
      @machine.event :enable
      @record = @model.new(:state => 'off')
      @transition = StateMachines::Transition.new(@record, @machine, :enable, :off, :active)
    end

    it 'should_call_namespaced_before_event_method' do
      observer = new_observer(@model) do
        def before_enable_alarm(*args)
          notifications << args
        end
      end
      instance = observer.instance

      @transition.perform
      assert_equal [[@record, @transition]], instance.notifications
    end

    it 'should_call_namespaced_after_event_method' do
      observer = new_observer(@model) do
        def after_enable_alarm(*args)
          notifications << args
        end
      end
      instance = observer.instance

      @transition.perform
      assert_equal [[@record, @transition]], instance.notifications
    end
  end

  context 'WithFailureCallbacks' do
    before(:each) do
      @model = new_model { include ActiveModel::Observing }
      @machine = StateMachines::Machine.new(@model)
      @machine.state :parked, :idling
      @machine.event :ignite
      @record = @model.new(:state => 'parked')
      @transition = StateMachines::Transition.new(@record, @machine, :ignite, :parked, :idling)

      @notifications = []

      # Create callbacks
      @machine.before_transition { false }
      @machine.after_failure { @notifications << :callback_after_failure }

      # Create observer callbacks
      observer = new_observer(@model) do
        def after_failure_to_ignite(*args)
          notifications << :observer_after_failure_ignite
        end

        def after_failure_to_transition(*args)
          notifications << :observer_after_failure_transition
        end
      end
      instance = observer.instance
      instance.notifications = @notifications

      @transition.perform
    end

    it 'should_invoke_callbacks_in_specific_order' do
      expected = [
          :callback_after_failure,
          :observer_after_failure_ignite,
          :observer_after_failure_transition
      ]

      assert_equal expected, @notifications
    end
  end

  context 'WithMixedCallbacks' do
    before(:each) do
      @model = new_model { include ActiveModel::Observing }
      @machine = StateMachines::Machine.new(@model)
      @machine.state :parked, :idling
      @machine.event :ignite
      @record = @model.new(:state => 'parked')
      @transition = StateMachines::Transition.new(@record, @machine, :ignite, :parked, :idling)

      @notifications = []

      # Create callbacks
      @machine.before_transition { @notifications << :callback_before_transition }
      @machine.after_transition { @notifications << :callback_after_transition }
      @machine.around_transition { |block| @notifications << :callback_around_before_transition; block.call; @notifications << :callback_around_after_transition }

      # Create observer callbacks
      observer = new_observer(@model) do
        def before_ignite(*args)
          notifications << :observer_before_ignite
        end

        def before_transition(*args)
          notifications << :observer_before_transition
        end

        def after_ignite(*args)
          notifications << :observer_after_ignite
        end

        def after_transition(*args)
          notifications << :observer_after_transition
        end
      end
      instance = observer.instance
      instance.notifications = @notifications

      @transition.perform
    end

    it 'should_invoke_callbacks_in_specific_order' do
      expected = [
          :callback_before_transition,
          :callback_around_before_transition,
          :observer_before_ignite,
          :observer_before_transition,
          :callback_around_after_transition,
          :callback_after_transition,
          :observer_after_ignite,
          :observer_after_transition
      ]

      assert_equal expected, @notifications
    end
  end

  context 'WithInternationalization' do
    before(:each) do
      I18n.backend = I18n::Backend::Simple.new

      # Initialize the backend
      I18n.backend.translate(:en, 'activemodel.errors.messages.invalid_transition', :event => 'ignite', :value => 'idling')

      @model = new_model { include ActiveModel::Validations }
    end

    it 'should_use_defaults' do
      I18n.backend.store_translations(:en, {
          :activemodel => {:errors => {:messages => {:invalid_transition => 'cannot %{event}'}}}
      })

      machine = StateMachines::Machine.new(@model, :action => :save)
      machine.state :parked, :idling
      machine.event :ignite

      record = @model.new(:state => 'idling')

      machine.invalidate(record, :state, :invalid_transition, [[:event, 'ignite']])
      assert_equal ['State cannot ignite'], record.errors.full_messages
    end

    it 'should_allow_customized_error_key' do
      I18n.backend.store_translations(:en, {
          :activemodel => {:errors => {:messages => {:bad_transition => 'cannot %{event}'}}}
      })

      machine = StateMachines::Machine.new(@model, :action => :save, :messages => {:invalid_transition => :bad_transition})
      machine.state :parked, :idling

      record = @model.new
      record.state = 'idling'

      machine.invalidate(record, :state, :invalid_transition, [[:event, 'ignite']])
      assert_equal ['State cannot ignite'], record.errors.full_messages
    end

    it 'should_allow_customized_error_string' do
      machine = StateMachines::Machine.new(@model, :action => :save, :messages => {:invalid_transition => 'cannot %{event}'})
      machine.state :parked, :idling

      record = @model.new(:state => 'idling')

      machine.invalidate(record, :state, :invalid_transition, [[:event, 'ignite']])
      assert_equal ['State cannot ignite'], record.errors.full_messages
    end

    it 'should_allow_customized_state_key_scoped_to_class_and_machine' do
      I18n.backend.store_translations(:en, {
          :activemodel => {:state_machines => {:'bar/foo' => {:state => {:states => {:parked => 'shutdown'}}}}}
      })

      machine = StateMachines::Machine.new(@model)
      machine.state :parked

      assert_equal 'shutdown', machine.state(:parked).human_name
    end

    it 'should_allow_customized_state_key_scoped_to_class' do
      I18n.backend.store_translations(:en, {
          :activemodel => {:state_machines => {:'bar/foo' => {:states => {:parked => 'shutdown'}}}}
      })

      machine = StateMachines::Machine.new(@model)
      machine.state :parked

      assert_equal 'shutdown', machine.state(:parked).human_name
    end

    it 'should_allow_customized_state_key_scoped_to_machine' do
      I18n.backend.store_translations(:en, {
          :activemodel => {:state_machines => {:state => {:states => {:parked => 'shutdown'}}}}
      })

      machine = StateMachines::Machine.new(@model)
      machine.state :parked

      assert_equal 'shutdown', machine.state(:parked).human_name
    end

    it 'should_allow_customized_state_key_unscoped' do
      I18n.backend.store_translations(:en, {
          :activemodel => {:state_machines => {:states => {:parked => 'shutdown'}}}
      })

      machine = StateMachines::Machine.new(@model)
      machine.state :parked

      assert_equal 'shutdown', machine.state(:parked).human_name
    end

    it 'should_support_nil_state_key' do
      I18n.backend.store_translations(:en, {
          :activemodel => {:state_machines => {:states => {:nil => 'empty'}}}
      })

      machine = StateMachines::Machine.new(@model)

      assert_equal 'empty', machine.state(nil).human_name
    end

    it 'should_allow_customized_event_key_scoped_to_class_and_machine' do
      I18n.backend.store_translations(:en, {
          :activemodel => {:state_machines => {:'bar/foo' => {:state => {:events => {:park => 'stop'}}}}}
      })

      machine = StateMachines::Machine.new(@model)
      machine.event :park

      assert_equal 'stop', machine.event(:park).human_name
    end

    it 'should_allow_customized_event_key_scoped_to_class' do
      I18n.backend.store_translations(:en, {
          :activemodel => {:state_machines => {:'bar/foo' => {:events => {:park => 'stop'}}}}
      })

      machine = StateMachines::Machine.new(@model)
      machine.event :park

      assert_equal 'stop', machine.event(:park).human_name
    end

    it 'should_allow_customized_event_key_scoped_to_machine' do
      I18n.backend.store_translations(:en, {
          :activemodel => {:state_machines => {:state => {:events => {:park => 'stop'}}}}
      })

      machine = StateMachines::Machine.new(@model)
      machine.event :park

      assert_equal 'stop', machine.event(:park).human_name
    end

    it 'should_allow_customized_event_key_unscoped' do
      I18n.backend.store_translations(:en, {
          :activemodel => {:state_machines => {:events => {:park => 'stop'}}}
      })

      machine = StateMachines::Machine.new(@model)
      machine.event :park

      assert_equal 'stop', machine.event(:park).human_name
    end

    it 'should_only_add_locale_once_in_load_path' do
      assert_equal 1, I18n.load_path.select { |path| path =~ %r{active_model/locale\.rb$} }.length

      # Create another ActiveModel model that will triger the i18n feature
      new_model

      assert_equal 1, I18n.load_path.select { |path| path =~ %r{active_model/locale\.rb$} }.length
    end

    context 'loading locale' do
      before(:each) do
        @original_load_path = I18n.load_path
        I18n.backend = I18n::Backend::Simple.new
      end
      it 'should_add_locale_to_beginning_of_load_path' do
        app_locale = File.dirname(__FILE__) + '/support/en.yml'
        default_locale = File.dirname(__FILE__) + '/../lib/state_machines/integrations/active_model/locale.rb'
        I18n.load_path = [app_locale]

        StateMachines::Machine.new(@model)

        assert_equal [default_locale, app_locale].map { |path| File.expand_path(path) }, I18n.load_path.map { |path| File.expand_path(path) }

      end

      it 'should_prefer_other_locales_first' do

        I18n.load_path = [File.dirname(__FILE__) + '/support/en.yml']

        machine = StateMachines::Machine.new(@model)
        machine.state :parked, :idling
        machine.event :ignite

        record = @model.new(:state => 'idling')

        machine.invalidate(record, :state, :invalid_transition, [[:event, 'ignite']])
        assert_equal ['State cannot ignite'], record.errors.full_messages


      end

      after(:each) do
        I18n.load_path = @original_load_path
      end
    end
  end

end