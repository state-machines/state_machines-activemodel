require 'active_model'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/module/attribute_accessors.rb'
require 'state_machines'
require 'state_machines/integrations/base'
require 'state_machines/integrations/active_model/version'

module StateMachines
  module Integrations #:nodoc:
    # Adds support for integrating state machines with ActiveModel classes.
    #
    # == Examples
    #
    # If using ActiveModel directly within your class, then any one of the
    # following features need to be included in order for the integration to be
    # detected:
    # * ActiveModel::Validations
    #
    # Below is an example of a simple state machine defined within an
    # ActiveModel class:
    #
    #   class Vehicle
    #     include ActiveModel::Validations
    #
    #     attr_accessor :state
    #     define_attribute_methods [:state]
    #
    #     state_machine :initial => :parked do
    #       event :ignite do
    #         transition :parked => :idling
    #       end
    #     end
    #   end
    #
    # The examples in the sections below will use the above class as a
    # reference.
    #
    # == Actions
    #
    # By default, no action will be invoked when a state is transitioned.  This
    # means that if you want to save changes when transitioning, you must
    # define the action yourself like so:
    #
    #   class Vehicle
    #     include ActiveModel::Validations
    #     attr_accessor :state
    #
    #     state_machine :action => :save do
    #       ...
    #     end
    #
    #     def save
    #       # Save changes
    #     end
    #   end
    #
    # == Validations
    #
    # As mentioned in StateMachine::Machine#state, you can define behaviors,
    # like validations, that only execute for certain states. One *important*
    # caveat here is that, due to a constraint in ActiveModel's validation
    # framework, custom validators will not work as expected when defined to run
    # in multiple states.  For example:
    #
    #   class Vehicle
    #     include ActiveModel::Validations
    #
    #     state_machine do
    #       ...
    #       state :first_gear, :second_gear do
    #         validate :speed_is_legal
    #       end
    #     end
    #   end
    #
    # In this case, the <tt>:speed_is_legal</tt> validation will only get run
    # for the <tt>:second_gear</tt> state.  To avoid this, you can define your
    # custom validation like so:
    #
    #   class Vehicle
    #     include ActiveModel::Validations
    #
    #     state_machine do
    #       ...
    #       state :first_gear, :second_gear do
    #         validate {|vehicle| vehicle.speed_is_legal}
    #       end
    #     end
    #   end
    #
    # == Validation errors
    #
    # In order to hook in validation support for your model, the
    # ActiveModel::Validations feature must be included.  If this is included
    # and an event fails to successfully fire because there are no matching
    # transitions for the object, a validation error is added to the object's
    # state attribute to help in determining why it failed.
    #
    # For example,
    #
    #   vehicle = Vehicle.new
    #   vehicle.ignite                # => false
    #   vehicle.errors.full_messages  # => ["State cannot transition via \"ignite\""]
    #
    # In addition, if you're using the <tt>ignite!</tt> version of the event,
    # then the failure reason (such as the current validation errors) will be
    # included in the exception that gets raised when the event fails.  For
    # example, assuming there's a validation on a field called +name+ on the class:
    #
    #   vehicle = Vehicle.new
    #   vehicle.ignite!       # => StateMachine::InvalidTransition: Cannot transition state via :ignite from :parked (Reason(s): Name cannot be blank)
    #
    # === Security implications
    #
    # Beware that public event attributes mean that events can be fired
    # whenever mass-assignment is being used.  If you want to prevent malicious
    # users from tampering with events through URLs / forms, the attribute
    # should be protected like so:
    #
    #   class Vehicle
    #     include ActiveModel::MassAssignmentSecurity
    #     attr_accessor :state
    #
    #     attr_protected :state_event
    #     # attr_accessible ... # Alternative technique
    #
    #     state_machine do
    #       ...
    #     end
    #   end
    #
    # If you want to only have *some* events be able to fire via mass-assignment,
    # you can build two state machines (one public and one protected) like so:
    #
    #   class Vehicle
    #     attr_accessor :state
    #
    #     attr_protected :state_event # Prevent access to events in the first machine
    #
    #     state_machine do
    #       # Define private events here
    #     end
    #
    #     # Public machine targets the same state as the private machine
    #     state_machine :public_state, :attribute => :state do
    #       # Define public events here
    #     end
    #   end
    #
    # == Callbacks
    #
    # All before/after transition callbacks defined for ActiveModel models
    # behave in the same way that other ActiveSupport callbacks behave.  The
    # object involved in the transition is passed in as an argument.
    #
    # For example,
    #
    #   class Vehicle
    #     include ActiveModel::Validations
    #     attr_accessor :state
    #
    #     state_machine :initial => :parked do
    #       before_transition any => :idling do |vehicle|
    #         vehicle.put_on_seatbelt
    #       end
    #
    #       before_transition do |vehicle, transition|
    #         # log message
    #       end
    #
    #       event :ignite do
    #         transition :parked => :idling
    #       end
    #     end
    #
    #     def put_on_seatbelt
    #       ...
    #     end
    #   end
    #
    # Note, also, that the transition can be accessed by simply defining
    # additional arguments in the callback block.
    #
    # == Observers
    #
    # In order to hook in observer support for your application, the
    # ActiveModel::Observing feature must be included.  This can be added by including the
    # https://github.com/state-machines/state_machines-activemodel-observers gem in your
    # Gemfile. Because of the way
    # ActiveModel observers are designed, there is less flexibility around the
    # specific transitions that can be hooked in.  However, a large number of
    # hooks *are* supported.  For example, if a transition for a object's
    # +state+ attribute changes the state from +parked+ to +idling+ via the
    # +ignite+ event, the following observer methods are supported:
    # * before/after/after_failure_to-_ignite_from_parked_to_idling
    # * before/after/after_failure_to-_ignite_from_parked
    # * before/after/after_failure_to-_ignite_to_idling
    # * before/after/after_failure_to-_ignite
    # * before/after/after_failure_to-_transition_state_from_parked_to_idling
    # * before/after/after_failure_to-_transition_state_from_parked
    # * before/after/after_failure_to-_transition_state_to_idling
    # * before/after/after_failure_to-_transition_state
    # * before/after/after_failure_to-_transition
    #
    # The following class shows an example of some of these hooks:
    #
    #   class VehicleObserver < ActiveModel::Observer
    #     # Callback for :ignite event *before* the transition is performed
    #     def before_ignite(vehicle, transition)
    #       # log message
    #     end
    #
    #     # Callback for :ignite event *after* the transition has been performed
    #     def after_ignite(vehicle, transition)
    #       # put on seatbelt
    #     end
    #
    #     # Generic transition callback *before* the transition is performed
    #     def after_transition(vehicle, transition)
    #       Audit.log(vehicle, transition)
    #     end
    #
    #     def after_failure_to_transition(vehicle, transition)
    #       Audit.error(vehicle, transition)
    #     end
    #   end
    #
    # More flexible transition callbacks can be defined directly within the
    # model as described in StateMachine::Machine#before_transition
    # and StateMachine::Machine#after_transition.
    #
    # To define a single observer for multiple state machines:
    #
    #   class StateMachineObserver < ActiveModel::Observer
    #     observe Vehicle, Switch, Project
    #
    #     def after_transition(object, transition)
    #       Audit.log(object, transition)
    #     end
    #   end
    #
    # == Internationalization
    #
    # Any error message that is generated from performing invalid transitions
    # can be localized.  The following default translations are used:
    #
    #   en:
    #     activemodel:
    #       errors:
    #         messages:
    #           invalid: "is invalid"
    #           # %{value} = attribute value, %{state} = Human state name
    #           invalid_event: "cannot transition when %{state}"
    #           # %{value} = attribute value, %{event} = Human event name, %{state} = Human current state name
    #           invalid_transition: "cannot transition via %{event}"
    #
    # You can override these for a specific model like so:
    #
    #   en:
    #     activemodel:
    #       errors:
    #         models:
    #           user:
    #             invalid: "is not valid"
    #
    # In addition to the above, you can also provide translations for the
    # various states / events in each state machine.  Using the Vehicle example,
    # state translations will be looked for using the following keys, where
    # +model_name+ = "vehicle", +machine_name+ = "state" and +state_name+ = "parked":
    # * <tt>activemodel.state_machines.#{model_name}.#{machine_name}.states.#{state_name}</tt>
    # * <tt>activemodel.state_machines.#{model_name}.states.#{state_name}</tt>
    # * <tt>activemodel.state_machines.#{machine_name}.states.#{state_name}</tt>
    # * <tt>activemodel.state_machines.states.#{state_name}</tt>
    #
    # Event translations will be looked for using the following keys, where
    # +model_name+ = "vehicle", +machine_name+ = "state" and +event_name+ = "ignite":
    # * <tt>activemodel.state_machines.#{model_name}.#{machine_name}.events.#{event_name}</tt>
    # * <tt>activemodel.state_machines.#{model_name}.events.#{event_name}</tt>
    # * <tt>activemodel.state_machines.#{machine_name}.events.#{event_name}</tt>
    # * <tt>activemodel.state_machines.events.#{event_name}</tt>
    #
    # An example translation configuration might look like so:
    #
    #   es:
    #     activemodel:
    #       state_machines:
    #         states:
    #           parked: 'estacionado'
    #         events:
    #           park: 'estacionarse'
    #
    # == Dirty Attribute Tracking
    #
    # When using the ActiveModel::Dirty extension, your model will keep track of
    # any changes that are made to attributes.  Depending on your ORM, an object
    # will only be saved when there are attributes that have changed on the
    # object.  When integrating with state_machine, typically the +state+ field
    # will be marked as dirty after a transition occurs.  In some situations,
    # however, this isn't the case.
    #
    # If you define loopback transitions in your state machine, the value for
    # the machine's attribute (e.g. state) will not change.  Unless you explicitly
    # indicate so, this means that your object won't persist anything on a
    # loopback.  For example:
    #
    #   class Vehicle
    #     include ActiveModel::Validations
    #     include ActiveModel::Dirty
    #     attr_accessor :state
    #
    #     state_machine :initial => :parked do
    #       event :park do
    #         transition :parked => :parked, ...
    #       end
    #     end
    #   end
    #
    # If, instead, you'd like your object to always persist regardless of
    # whether the value actually changed, you can do so by using the
    # <tt>#{attribute}_will_change!</tt> helpers or defining a +before_transition+
    # callback that actually changes an attribute on the model.  For example:
    #
    #   class Vehicle
    #     ...
    #     state_machine :initial => :parked do
    #       before_transition all => same do |vehicle|
    #         vehicle.state_will_change!
    #
    #         # Alternative solution, updating timestamp
    #         # vehicle.updated_at = Time.current
    #       end
    #     end
    #   end
    #
    # == Creating new integrations
    #
    # If you want to integrate state_machine with an ORM that implements parts
    # or all of the ActiveModel API, only the machine defaults need to be
    # specified.  Otherwise, the implementation is similar to any other
    # integration.
    #
    # For example,
    #
    #   module StateMachine::Integrations::MyORM
    #     include ActiveModel
    #
    #     mattr_accessor(:defaults) { :action => :persist }
    #
    #     def self.matches?(klass)
    #       defined?(::MyORM::Base) && klass <= ::MyORM::Base
    #     end
    #
    #     protected
    #
    #     def runs_validations_on_action?
    #      action == :persist
    #     end
    #   end
    #
    # If you wish to implement other features, such as attribute initialization
    # with protected attributes, named scopes, or database transactions, you
    # must add these independent of the ActiveModel integration.  See the
    # ActiveRecord implementation for examples of these customizations.
    module ActiveModel
      include Base

      @defaults = {}

      # Classes that include ActiveModel::Validations
      # will automatically use the ActiveModel integration.
      def self.matching_ancestors
        [::ActiveModel, ::ActiveModel::Validations]
      end

      # Adds a validation error to the given object
      def invalidate(object, attribute, message, values = [])
        if supports_validations?
          attribute = self.attribute(attribute)
          options = values.reduce({}) do |h, (key, value)|
            h[key] = value
            h
          end

          default_options = default_error_message_options(object, attribute, message)
          object.errors.add(attribute, message, **options, **default_options)
        end
      end

      # Describes the current validation errors on the given object.  If none
      # are specific, then the default error is interpeted as a "halt".
      def errors_for(object)
        object.errors.empty? ? 'Transition halted' : object.errors.full_messages * ', '
      end

      # Resets any errors previously added when invalidating the given object
      def reset(object)
        object.errors.clear if supports_validations?
      end

      # Runs state events around the object's validation process
      def around_validation(object)
        object.class.state_machines.transitions(object, action, after: false).perform { yield }
      end

      protected

      def define_state_initializer
        define_helper :instance, <<-end_eval, __FILE__, __LINE__ + 1
          def initialize(params = {})
            params.transform_keys! do |key|
              self.class.attribute_aliases[key.to_s] || key.to_s
            end if self.class.respond_to?(:attribute_aliases)

            self.class.state_machines.initialize_states(self, {}, params) { super }
          end
        end_eval
      end

      # Whether validations are supported in the integration.  Only true if
      # the ActiveModel feature is enabled on the owner class.
      def supports_validations?
        defined?(::ActiveModel::Validations) && owner_class <= ::ActiveModel::Validations
      end

      # Do validations run when the action configured this machine is
      # invoked?  This is used to determine whether to fire off attribute-based
      # event transitions when the action is run.
      def runs_validations_on_action?
        false
      end

      # Gets the terminator to use for callbacks
      def callback_terminator
        @terminator ||= ->(result) { result == false }
      end

      # Determines the base scope to use when looking up translations
      def i18n_scope(klass)
        klass.i18n_scope
      end

      # The default options to use when generating messages for validation
      # errors
      def default_error_message_options(_object, _attribute, message)
        { message: @messages[message] }
      end

      # Translates the given key / value combo.  Translation keys are looked
      # up in the following order:
      # * <tt>#{i18n_scope}.state_machines.#{model_name}.#{machine_name}.#{plural_key}.#{value}</tt>
      # * <tt>#{i18n_scope}.state_machines.#{model_name}.#{plural_key}.#{value}</tt>
      # * <tt>#{i18n_scope}.state_machines.#{machine_name}.#{plural_key}.#{value}</tt>
      # * <tt>#{i18n_scope}.state_machines.#{plural_key}.#{value}</tt>
      #
      # If no keys are found, then the humanized value will be the fallback.
      def translate(klass, key, value)
        ancestors = ancestors_for(klass)
        group = key.to_s.pluralize
        value = value ? value.to_s : 'nil'

        # Generate all possible translation keys
        translations = ancestors.map { |ancestor| :"#{ancestor.model_name.to_s.underscore}.#{name}.#{group}.#{value}" }
        translations.concat(ancestors.map { |ancestor| :"#{ancestor.model_name.to_s.underscore}.#{group}.#{value}" })
        translations.concat([:"#{name}.#{group}.#{value}", :"#{group}.#{value}", value.humanize.downcase])
        I18n.translate(translations.shift, default: translations, scope: [i18n_scope(klass), :state_machines])
      end

      # Build a list of ancestors for the given class to use when
      # determining which localization key to use for a particular string.
      def ancestors_for(klass)
        klass.lookup_ancestors
      end

      # Skips defining reader/writer methods since this is done automatically
      def define_state_accessor
        name = self.name

        owner_class.validates_each(attribute) do |object|
          machine = object.class.state_machine(name)
          machine.invalidate(object, :state, :invalid) unless machine.states.match(object)
        end if supports_validations?
      end

      # Adds hooks into validation for automatically firing events
      def define_action_helpers
        super
        define_validation_hook if runs_validations_on_action?
      end

      # Hooks into validations by defining around callbacks for the
      # :validation event
      def define_validation_hook
        owner_class.set_callback(:validation, :around, self, prepend: true)
      end

      # Creates a new callback in the callback chain, always inserting it
      # before the default Observer callbacks that were created after
      # initialization.
      def add_callback(type, options, &block)
        options[:terminator] = callback_terminator
        super
      end

      # Configures new states with the built-in humanize scheme
      def add_states(*)
        super.each do |new_state|
          new_state.human_name ||= ->(state, klass) { translate(klass, :state, state.name) }
        end
      end

      # Configures new event with the built-in humanize scheme
      def add_events(*)
        super.each do |new_event|
          new_event.human_name = ->(event, klass) { translate(klass, :event, event.name) }
        end
      end
    end
    register(ActiveModel)
  end
end
