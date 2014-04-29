require 'spec_helper'

describe StateMachines::Integrations::ActiveModel do
  it { expect(StateMachines::Integrations::ActiveModel.integration_name).to eq(:active_model) }

  it 'should_be_available' do
    expect(StateMachines::Integrations::ActiveModel.available?).to be_truthy
  end

  if defined?(ActiveModel::Observing)
    it 'should_match_if_class_includes_observing_feature' do
      expect(StateMachines::Integrations::ActiveModel.matches?(new_model { include ActiveModel::Observing })).to be_truthy
    end
  end

  it 'should_match_if_class_includes_validations_feature' do
    expect(StateMachines::Integrations::ActiveModel.matches?(new_model { include ActiveModel::Validations })).to be_truthy
  end

  it 'should_not_match_if_class_does_not_include_active_model_features' do
    expect(StateMachines::Integrations::ActiveModel.matches?(new_model)).to be_falsy
  end

  it 'should_have_no_defaults' do
    expect(StateMachines::Integrations::ActiveModel.defaults).to eq({})
  end
end