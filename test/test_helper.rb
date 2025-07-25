# frozen_string_literal: true

require 'debug'

require 'state_machines-activemodel'
require 'minitest/autorun'
require 'minitest/reporters'
require 'active_support/all'
Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new]
I18n.enforce_available_locales = true

class BaseTestCase < ActiveSupport::TestCase
  protected

  # Creates a plain model without ActiveModel features
  def new_plain_model(&block)
    model = Class.new do
      def self.name
        'Foo'
      end
    end

    model.class_eval(&block) if block_given?

    model
  end

  # Creates a new ActiveModel model (and the associated table)
  def new_model(&block)
    model = Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Dirty

      attribute :state, :string

      def self.name
        'Foo'
      end

      def self.create
        new.tap { |instance| instance.save if instance.respond_to?(:save) }
      end
    end

    model.class_eval(&block) if block_given?

    model
  end
end
