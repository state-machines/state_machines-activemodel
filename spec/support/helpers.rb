# Creates a new ActiveModel model (and the associated table)

class Bar

end

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
      attrs.each {|attr, value| send("#{attr}=", value)}
      @changed_attributes = {}
    end

    def attributes
      @attributes ||= {}
    end

    def save
      @changed_attributes = {}
      true
    end
  end

  model = Class.new(parent) do
    def self.name
      'Bar::Foo'
    end

    model_attribute :state
  end
  model.class_eval(&block) if block_given?
  model
end


# Creates a new ActiveModel observer
def new_observer(model, &block)
  observer = Class.new(ActiveModel::Observer) do
    attr_accessor :notifications

    def initialize
      super
      @notifications = []
    end
  end
  observer.observe(model)
  observer.class_eval(&block) if block_given?
  observer
end