# frozen_string_literal: true
require 'rspec/mocks/standalone'

# This class behaves as an extension of rspec-mocks' instance_spy.
# It is intended to be extended and used to make mocking models much simpler!
#
# To create a new subclass, the following methods must be overridden:
#   - self.klass must return the class that the subclass is mocking
#   - self.klass_name must return a string that matches the class being mocked
#
# Some examples using the EquipmentModelMock subclass:
#   A mock that can be "found" with EquipmentModel#find:
#     EquipmentModelMock.new(traits: [:findable])
#   A mock with a set of attributes:
#     EquipmentModelMock.new(name: 'Camera', late_fee: 3)
#   A mock with attributes and method stubs:
#     EquipmentModelMock.new(name: 'Camera', model_restriced: false)
#   A findable mock with attributes:
#     EquipmentModelMock.new(traits: [:findable], name: 'Camera')
#
# A trait can be any method that exists on the mocker superclass or child class.
# To create an EquipmentModel that belongs to an existing category, camera:
#   EquipmentModelMock.new(traits: [[:with_category, cat: camera]])
#
# Use caution before adding methods -- any method defined here should be usable
# by all subclasses, with the exception of the association stub methods.

class Mocker < RSpec::Mocks::InstanceVerifyingDouble
  include RSpec::Mocks

  FIND_METHODS = [:find, :find_by_id].freeze

  def initialize(traits: [], **attrs)
    # from RSpec::Mocks::ExampleMethods
    # combination of #declare_verifying_double and #declare_double
    ref = ObjectReference.for(self.class.klass_name)
    RSpec::Mocks.configuration.verifying_double_callbacks.each do |block|
      block.call(ref)
    end
    attrs ||= {}
    super(ref, attrs)
    as_null_object
    process_traits(traits)
  end

  def process_traits(traits)
    traits.each { |t| send(*t) }
  end

  private

  def klass
    Object
  end

  def klass_name
    'Object'
  end

  def spy
    self
  end

  # lets us use rspec-mock syntax in mockers
  def receive(method_name, &block)
    Matchers::Receive.new(method_name, block)
  end

  def allow(target)
    AllowanceTarget.new(target)
  end

  # Traits
  def findable
    id = FactoryGirl.generate(:unique_id)
    allow(spy).to receive(:id).and_return(id)
    FIND_METHODS.each do |method|
      allow(self.class.klass).to receive(method)
      allow(self.class.klass).to receive(method).with(id).and_return(spy)
      allow(self.class.klass).to receive(method).with(id.to_s).and_return(spy)
    end
  end

  # Generalized association stubs
  def child_of_has_many(mocked_parent:, parent_sym:, child_sym:)
    allow(spy).to receive(parent_sym).and_return(mocked_parent)
    children = if mocked_parent.send(child_sym).is_a? Array
                 mocked_parent.send(child_sym) << spy
               else
                 [spy]
               end
    allow(mocked_parent).to receive(child_sym).and_return(children)
  end

  def parent_has_many(mocked_children:, parent_sym:, child_sym:)
    if mocked_children.is_a? Array
      mocked_children.each do |child|
        allow(child).to receive(parent_sym).and_return(spy)
      end
    end
    allow(spy).to receive(child_sym).and_return(mocked_children)
  end
end
