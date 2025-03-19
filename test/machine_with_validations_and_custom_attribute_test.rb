# frozen_string_literal: true

require 'test_helper'

class MachineWithValidationsAndCustomAttributeTest < BaseTestCase
  def setup
    @model = new_model { include ActiveModel::Validations }

    @machine = StateMachines::Machine.new(@model, :status, attribute: :state)
    @machine.state :parked

    @record = @model.new
  end

  def test_should_add_validation_errors_to_custom_attribute
    @record.state = 'invalid'

    assert !@record.valid?
    assert_equal ['State is invalid'], @record.errors.full_messages

    @record.state = 'parked'
    assert @record.valid?
  end
end
