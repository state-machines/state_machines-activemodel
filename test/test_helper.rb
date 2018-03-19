begin
  require 'pry-byebug'
rescue LoadError
end

require 'state_machines-activemodel'
require 'minitest/autorun'
require 'minitest/reporters'
require 'active_support/all'
Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new]
I18n.enforce_available_locales = true

class BaseTestCase < MiniTest::Test
  protected
  # Creates a new ActiveModel model (and the associated table)
  def new_model(&block)
    # Simple ActiveModel superclass
    parent = Class.new do
      def self.model_attribute(name)
        define_method(name) { instance_variable_defined?("@#{name}") ? instance_variable_get("@#{name}") : nil }
        define_method("#{name}=") do |value|
          send("#{name}_will_change!") if self.class <= ActiveModel::Dirty && value != send(name)
          instance_variable_set("@#{name}", value)
        end
      end

      def self.create
        object = new
        object.save
        object
      end

      def initialize(attrs = {})
        attrs.each { |attr, value| send("#{attr}=", value) }
      end

      def attributes
        @attributes ||= {}
      end

      def save
        true
      end
    end

    model = Class.new(parent) do
      def self.name
        'Foo'
      end

      model_attribute :state
    end
    model.class_eval(&block) if block_given?
    model
  end
end
