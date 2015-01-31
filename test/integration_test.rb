require_relative 'test_helper'

class IntegrationTest < BaseTestCase
  def test_should_be_registered
    assert_includes StateMachines::Integrations.list, StateMachines::Integrations::ActiveModel
  end

  def test_should_register_one_integration
    assert_equal 1, StateMachines::Integrations.list.size
  end

  def test_should_have_an_integration_name
    assert_equal :active_model, StateMachines::Integrations::ActiveModel.integration_name
  end

  def test_should_match_if_class_includes_validations_feature
    assert StateMachines::Integrations::ActiveModel.matches?(new_model { include ActiveModel::Validations })
  end

  def test_should_not_match_if_class_does_not_include_active_model_features
    refute StateMachines::Integrations::ActiveModel.matches?(new_model)
  end

  def test_should_have_no_defaults
    assert_equal({}, StateMachines::Integrations::ActiveModel.defaults)
  end
end
