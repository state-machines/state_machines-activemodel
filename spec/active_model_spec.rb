require 'spec_helper'

describe StateMachines::Integrations::ActiveModel do
  context 'ByDefault' do
    let(:model) { new_model }
    let!(:machine) { StateMachines::Machine.new(model, :integration => :active_model) }

    it 'should_not_have_action' do
      expect(machine.action).to be_nil
    end

    it 'should_use_transactions' do
      expect(machine.use_transactions).to be_truthy
    end

    it 'should_not_have_any_before_callbacks' do
      expect(machine.callbacks[:before].size).to eq(0)
    end

    it 'should_not_have_any_after_callbacks' do
      expect(machine.callbacks[:after].size).to eq(0)
    end
  end

  context 'WithStates' do
    before(:each) do
      @model = new_model
      @machine = StateMachines::Machine.new(@model)
      @machine.state :first_gear
    end

    it 'should_humanize_name' do
      expect(@machine.state(:first_gear).human_name).to eq('first gear')
    end
  end

  context 'WithStaticInitialState' do
    before(:each) do
      @model = new_model
      @machine = StateMachines::Machine.new(@model, :initial => :parked, :integration => :active_model)
    end

    it 'should_set_initial_state_on_created_object' do
      record = @model.new
      expect(record.state).to eq('parked')
    end
  end

  context 'WithDynamicInitialState' do
    before(:each) do
      @model = new_model
      @machine = StateMachines::Machine.new(@model, :initial => lambda { |object| :parked }, :integration => :active_model)
      @machine.state :parked
    end

    it 'should_set_initial_state_on_created_object' do
      record = @model.new
      assert_equal 'parked', record.state
    end
  end

  context 'WithEvents' do
    before(:each) do
      @model = new_model
      @machine = StateMachines::Machine.new(@model)
      @machine.event :shift_up
    end

    it 'should_humanize_name' do
      assert_equal 'shift up', @machine.event(:shift_up).human_name
    end
  end

  context 'WithModelStateAttribute' do
    before(:each) do
      @model = new_model
      @machine = StateMachines::Machine.new(@model, :initial => :parked, :integration => :active_model)
      @machine.other_states(:idling)

      @record = @model.new
    end

    it 'should_have_an_attribute_predicate' do
      assert @record.respond_to?(:state?)
    end

    it 'should_raise_exception_for_predicate_without_parameters' do
      assert_raise(ArgumentError) { @record.state? }
    end

    it 'should_return_false_for_predicate_if_does_not_match_current_value' do
      assert !@record.state?(:idling)
    end

    it 'should_return_true_for_predicate_if_matches_current_value' do
      assert @record.state?(:parked)
    end

    it 'should_raise_exception_for_predicate_if_invalid_state_specified' do
      assert_raise(IndexError) { @record.state?(:invalid) }
    end
  end

  context 'WithNonModelStateAttributeUndefined' do
    before(:each) do
      @model = new_model do
        def initialize
        end
      end

      @machine = StateMachines::Machine.new(@model, :status, :initial => :parked, :integration => :active_model)
      @machine.other_states(:idling)
      @record = @model.new
    end

    it 'should_not_define_a_reader_attribute_for_the_attribute' do
      assert !@record.respond_to?(:status)
    end

    it 'should_not_define_a_writer_attribute_for_the_attribute' do
      assert !@record.respond_to?(:status=)
    end

    it 'should_define_an_attribute_predicate' do
      assert @record.respond_to?(:status?)
    end
  end

  context 'WithInitializedState' do
    before(:each) do
      @model = new_model
      @machine = StateMachines::Machine.new(@model, :initial => :parked, :integration => :active_model)
      @machine.state :idling
    end

    it 'should_allow_nil_initial_state_when_static' do
      @machine.state nil

      record = @model.new(:state => nil)
      assert_nil record.state
    end

    it 'should_allow_nil_initial_state_when_dynamic' do
      @machine.state nil

      @machine.initial_state = lambda { :parked }
      record = @model.new(:state => nil)
      assert_nil record.state
    end

    it 'should_allow_different_initial_state_when_static' do
      record = @model.new(:state => 'idling')
      assert_equal 'idling', record.state
    end

    it 'should_allow_different_initial_state_when_dynamic' do
      @machine.initial_state = lambda { :parked }
      record = @model.new(:state => 'idling')
      assert_equal 'idling', record.state
    end

    it 'should_use_default_state_if_protected' do
      if defined?(ActiveModel::MassAssignmentSecurity)
        @model.class_eval do
          include ActiveModel::MassAssignmentSecurity
          attr_protected :state

          def initialize(attrs = {})
            initialize_state_machines do
              sanitize_for_mass_assignment(attrs).each { |attr, value| send("#{attr}=", value) } if attrs
              @changed_attributes = {}
            end
          end
        end

        record = @model.new(:state => 'idling')
        assert_equal 'parked', record.state

        record = @model.new(nil)
        assert_equal 'parked', record.state
      end
    end
  end

  context 'Multiple' do
    before(:each) do
      @model = new_model do
        model_attribute :status
      end

      @state_machine = StateMachines::Machine.new(@model, :initial => :parked, :integration => :active_model)
      @status_machine = StateMachines::Machine.new(@model, :status, :initial => :idling, :integration => :active_model)
    end

    it 'should_should_initialize_each_state' do
      record = @model.new
      assert_equal 'parked', record.state
      assert_equal 'idling', record.status
    end
  end

  context 'WithDirtyAttributes' do
    before(:each) do
      @model = new_model do
        include ActiveModel::Dirty
        define_attribute_methods [:state]
      end
      @machine = StateMachines::Machine.new(@model, :initial => :parked)
      @machine.event :ignite
      @machine.state :idling

      @record = @model.create

      @transition = StateMachines::Transition.new(@record, @machine, :ignite, :parked, :idling)
      @transition.perform
    end

    it 'should_include_state_in_changed_attributes' do
      assert_equal %w(state), @record.changed
    end

    it 'should_track_attribute_change' do
      assert_equal %w(parked idling), @record.changes['state']
    end

    it 'should_not_reset_changes_on_multiple_transitions' do
      transition = StateMachines::Transition.new(@record, @machine, :ignite, :idling, :idling)
      transition.perform

      assert_equal %w(parked idling), @record.changes['state']
    end
  end

  context 'WithDirtyAttributesDuringLoopback' do
    before(:each) do
      @model = new_model do
        include ActiveModel::Dirty
        define_attribute_methods [:state]
      end
      @machine = StateMachines::Machine.new(@model, :initial => :parked)
      @machine.event :park

      @record = @model.create

      @transition = StateMachines::Transition.new(@record, @machine, :park, :parked, :parked)
      @transition.perform
    end

    it 'should_not_include_state_in_changed_attributes' do
      assert_equal [], @record.changed
    end

    it 'should_not_track_attribute_changes' do
      assert_equal nil, @record.changes['state']
    end
  end

  context 'WithDirtyAttributesAndCustomAttribute' do
    before(:each) do
      @model = new_model do
        include ActiveModel::Dirty
        model_attribute :status
        define_attribute_methods [:status]
      end
      @machine = StateMachines::Machine.new(@model, :status, :initial => :parked)
      @machine.event :ignite
      @machine.state :idling

      @record = @model.create

      @transition = StateMachines::Transition.new(@record, @machine, :ignite, :parked, :idling)
      @transition.perform
    end

    it 'should_include_state_in_changed_attributes' do
      assert_equal %w(status), @record.changed
    end

    it 'should_track_attribute_change' do
      assert_equal %w(parked idling), @record.changes['status']
    end

    it 'should_not_reset_changes_on_multiple_transitions' do
      transition = StateMachines::Transition.new(@record, @machine, :ignite, :idling, :idling)
      transition.perform

      assert_equal %w(parked idling), @record.changes['status']
    end
  end

  context 'WithDirtyAttributeAndCustomAttributesDuringLoopback' do
    before(:each) do
      @model = new_model do
        include ActiveModel::Dirty
        model_attribute :status
        define_attribute_methods [:status]
      end
      @machine = StateMachines::Machine.new(@model, :status, :initial => :parked)
      @machine.event :park

      @record = @model.create

      @transition = StateMachines::Transition.new(@record, @machine, :park, :parked, :parked)
      @transition.perform
    end

    it 'should_not_include_state_in_changed_attributes' do
      assert_equal [], @record.changed
    end

    it 'should_not_track_attribute_changes' do
      assert_equal nil, @record.changes['status']
    end
  end

  context 'WithDirtyAttributeAndStateEvents' do
    before(:each) do
      @model = new_model do
        include ActiveModel::Dirty
        define_attribute_methods [:state]
      end
      @machine = StateMachines::Machine.new(@model, :action => :save, :initial => :parked)
      @machine.event :ignite

      @record = @model.create
      @record.state_event = 'ignite'
    end

    it 'should_not_include_state_in_changed_attributes' do
      assert_equal [], @record.changed
    end

    it 'should_not_track_attribute_change' do
      assert_equal nil, @record.changes['state']
    end
  end

  context 'WithCallbacks' do
    before(:each) do
      @model = new_model
      @machine = StateMachines::Machine.new(@model, :initial => :parked, :integration => :active_model)
      @machine.other_states :idling
      @machine.event :ignite

      @record = @model.new(:state => 'parked')
      @transition = StateMachines::Transition.new(@record, @machine, :ignite, :parked, :idling)
    end

    it 'should_run_before_callbacks' do
      called = false
      @machine.before_transition {called = true}

      @transition.perform
      assert called
    end

    it 'should_pass_record_to_before_callbacks_with_one_argument' do
      record = nil
      @machine.before_transition {|arg| record = arg}

      @transition.perform
      assert_equal @record, record
    end

    it 'should_pass_record_and_transition_to_before_callbacks_with_multiple_arguments' do
      callback_args = nil
      @machine.before_transition {|*args| callback_args = args}

      @transition.perform
      assert_equal [@record, @transition], callback_args
    end

    it 'should_run_before_callbacks_outside_the_context_of_the_record' do
      context = nil
      @machine.before_transition {context = self}

      @transition.perform
      assert_equal self, context
    end

    it 'should_run_after_callbacks' do
      called = false
      @machine.after_transition {called = true}

      @transition.perform
      assert called
    end

    it 'should_pass_record_to_after_callbacks_with_one_argument' do
      record = nil
      @machine.after_transition {|arg| record = arg}

      @transition.perform
      assert_equal @record, record
    end

    it 'should_pass_record_and_transition_to_after_callbacks_with_multiple_arguments' do
      callback_args = nil
      @machine.after_transition {|*args| callback_args = args}

      @transition.perform
      assert_equal [@record, @transition], callback_args
    end

    it 'should_run_after_callbacks_outside_the_context_of_the_record' do
      context = nil
      @machine.after_transition {context = self}

      @transition.perform
      assert_equal self, context
    end

    it 'should_run_around_callbacks' do
      before_called = false
      after_called = false
      ensure_called = 0
      @machine.around_transition do |block|
        before_called = true
        begin
          block.call
        ensure
          ensure_called += 1
        end
        after_called = true
      end

      @transition.perform
      assert before_called
      assert after_called
      assert_equal ensure_called, 1
    end

    it 'should_include_transition_states_in_known_states' do
      @machine.before_transition :to => :first_gear, :do => lambda {}

      assert_equal [:parked, :idling, :first_gear], @machine.states.map {|state| state.name}
    end

    it 'should_allow_symbolic_callbacks' do
      callback_args = nil

      klass = class << @record; self; end
      klass.send(:define_method, :after_ignite) do |*args|
        callback_args = args
      end

      @machine.before_transition(:after_ignite)

      @transition.perform
      assert_equal [@transition], callback_args
    end

    it 'should_allow_string_callbacks' do
      class << @record
        attr_reader :callback_result
      end

      @machine.before_transition('@callback_result = [1, 2, 3]')
      @transition.perform

      assert_equal [1, 2, 3], @record.callback_result
    end
  end

  context 'WithFailedBeforeCallbacks' do
    before(:each) do
      @callbacks = []

      @model = new_model
      @machine = StateMachines::Machine.new(@model, :integration => :active_model)
      @machine.state :parked, :idling
      @machine.event :ignite
      @machine.before_transition {@callbacks << :before_1; false}
      @machine.before_transition {@callbacks << :before_2}
      @machine.after_transition {@callbacks << :after}
      @machine.around_transition {|block| @callbacks << :around_before; block.call; @callbacks << :around_after}

      @record = @model.new(:state => 'parked')
      @transition = StateMachines::Transition.new(@record, @machine, :ignite, :parked, :idling)
      @result = @transition.perform
    end

    it 'should_not_be_successful' do
      assert !@result
    end

    it 'should_not_change_current_state' do
      assert_equal 'parked', @record.state
    end

    it 'should_not_run_further_callbacks' do
      assert_equal [:before_1], @callbacks
    end
  end

  context 'WithFailedAfterCallbacks' do
    before(:each) do
      @callbacks = []

      @model = new_model
      @machine = StateMachines::Machine.new(@model, :integration => :active_model)
      @machine.state :parked, :idling
      @machine.event :ignite
      @machine.after_transition {@callbacks << :after_1; false}
      @machine.after_transition {@callbacks << :after_2}
      @machine.around_transition {|block| @callbacks << :around_before; block.call; @callbacks << :around_after}

      @record = @model.new(:state => 'parked')
      @transition = StateMachines::Transition.new(@record, @machine, :ignite, :parked, :idling)
      @result = @transition.perform
    end

    it 'should_be_successful' do
      assert @result
    end

    it 'should_change_current_state' do
      assert_equal 'idling', @record.state
    end

    it 'should_not_run_further_after_callbacks' do
      assert_equal [:around_before, :around_after, :after_1], @callbacks
    end
  end

  context 'WithValidations' do
    before(:each) do
      @model = new_model { include ActiveModel::Validations }
      @machine = StateMachines::Machine.new(@model, :action => :save)
      @machine.state :parked

      @record = @model.new
    end

    it 'should_invalidate_using_errors' do
      I18n.backend = I18n::Backend::Simple.new if Object.const_defined?(:I18n)
      @record.state = 'parked'

      @machine.invalidate(@record, :state, :invalid_transition, [[:event, 'park']])
      assert_equal ['State cannot transition via "park"'], @record.errors.full_messages
    end

    it 'should_auto_prefix_custom_attributes_on_invalidation' do
      @machine.invalidate(@record, :event, :invalid)

      assert_equal ['State event is invalid'], @record.errors.full_messages
    end

    it 'should_clear_errors_on_reset' do
      @record.state = 'parked'
      @record.errors.add(:state, 'is invalid')

      @machine.reset(@record)
      assert_equal [], @record.errors.full_messages
    end

    it 'should_be_valid_if_state_is_known' do
      @record.state = 'parked'

      assert @record.valid?
    end

    it 'should_not_be_valid_if_state_is_unknown' do
      @record.state = 'invalid'

      assert !@record.valid?
      assert_equal ['State is invalid'], @record.errors.full_messages
    end
  end

  context 'WithValidationsAndCustomAttribute' do
    before(:each) do
      @model = new_model { include ActiveModel::Validations }

      @machine = StateMachines::Machine.new(@model, :status, :attribute => :state)
      @machine.state :parked

      @record = @model.new
    end

    it 'should_add_validation_errors_to_custom_attribute' do
      @record.state = 'invalid'

      assert !@record.valid?
      assert_equal ['State is invalid'], @record.errors.full_messages

      @record.state = 'parked'
      assert @record.valid?
    end
  end

  context 'Errors' do
    before(:each) do
      @model = new_model { include ActiveModel::Validations }
      @machine = StateMachines::Machine.new(@model)
      @record = @model.new
    end

    it 'should_be_able_to_describe_current_errors' do
      @record.errors.add(:id, 'cannot be blank')
      @record.errors.add(:state, 'is invalid')
      assert_equal ['Id cannot be blank', 'State is invalid'], @machine.errors_for(@record).split(', ').sort
    end

    it 'should_describe_as_halted_with_no_errors' do
      assert_equal 'Transition halted', @machine.errors_for(@record)
    end
  end

  context 'WithStateDrivenValidations' do
    before(:each) do
      @model = new_model do
        include ActiveModel::Validations
        attr_accessor :seatbelt
      end

      @machine = StateMachines::Machine.new(@model)
      @machine.state :first_gear, :second_gear do
        validates_presence_of :seatbelt
      end
      @machine.other_states :parked
    end

    it 'should_be_valid_if_validation_fails_outside_state_scope' do
      record = @model.new(:state => 'parked', :seatbelt => nil)
      assert record.valid?
    end

    it 'should_be_invalid_if_validation_fails_within_state_scope' do
      record = @model.new(:state => 'first_gear', :seatbelt => nil)
      assert !record.valid?
    end

    it 'should_be_valid_if_validation_succeeds_within_state_scope' do
      record = @model.new(:state => 'second_gear', :seatbelt => true)
      assert record.valid?
    end
  end
end