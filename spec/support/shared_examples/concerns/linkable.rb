# frozen_string_literal: true
# based on http://stackoverflow.com/a/20010923/2187922

require 'spec_helper'

shared_examples_for 'linkable' do
  let(:model) { described_class } # the class that includes the concern

  context 'with no parameter' do
    it 'generates a markdown link with name as text when object exists' do
      obj = FactoryGirl.build(model.to_s.underscore.to_sym)
      obj.save(validate: false)

      # test without URL so we don't need to include routing here
      expect(obj.md_link).to include("[#{obj.name}](")
    end

    it "simply returns the name when object doesn't exist" do
      obj = FactoryGirl.build(model.to_s.underscore.to_sym)

      expect(obj.md_link).to eq(obj.name)
    end
  end

  context 'when text is passed' do
    it 'generates a markdown link with custom text when object exists' do
      obj = FactoryGirl.build(model.to_s.underscore.to_sym)
      obj.save(validate: false)

      # test without URL so we don't need to include routing here
      expect(obj.md_link('foo')).to include('[foo](')
    end

    it "simply returns the name when object doesn't exist" do
      obj = FactoryGirl.build(model.to_s.underscore.to_sym)

      expect(obj.md_link('foo')).to eq('foo')
    end
  end
end
