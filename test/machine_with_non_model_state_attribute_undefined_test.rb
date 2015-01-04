require_relative 'test_helper'

class MachineWithNonModelStateAttributeUndefinedTest < BaseTestCase
  def setup
    @model = new_model do
      def initialize
      end
    end

    @machine = StateMachines::Machine.new(@model, :status, initial: :parked, integration: :active_model)
    @machine.other_states(:idling)
    @record = @model.new
  end

  def test_should_not_define_a_reader_attribute_for_the_attribute
    assert !@record.respond_to?(:status)
  end

  def test_should_not_define_a_writer_attribute_for_the_attribute
    assert !@record.respond_to?(:status=)
  end

  def test_should_define_an_attribute_predicate
    assert @record.respond_to?(:status?)
  end
end
