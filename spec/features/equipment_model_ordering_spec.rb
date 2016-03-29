# frozen_string_literal: true

require 'spec_helper'

context 'table operations' do
  before do
    @eq_model2 =
      FactoryGirl.create(:equipment_model, category: @category, ordering: 3)
    @eq_model3 =
      FactoryGirl.create(:equipment_model, category: @category, ordering: 5)
    @eq_model.update_attribute('ordering', 1)
    sign_in_as_user @superuser
    visit category_equipment_models_path(@category.id)
  end
  after { sign_out }
  it 'swaps orderings and preserves neutral elements on down' do
    first('.glyphicon-arrow-down').click
    expect(@eq_model.reload.ordering).to eq(3)
    expect(@eq_model2.reload.ordering).to eq(1)
    expect(@eq_model3.reload.ordering).to eq(5)
  end
  it 'swaps orderings and preserves neutral elements on up' do
    all('.glyphicon-arrow-up').last.click
    expect(@eq_model.reload.ordering).to eq(1)
    expect(@eq_model2.reload.ordering).to eq(5)
    expect(@eq_model3.reload.ordering).to eq(3)
  end
  it 'does not allow priority above 1' do
    first('.glyphicon-arrow-up').click
    expect(@eq_model.reload.ordering).to eq(1)
    expect(@eq_model2.reload.ordering).to eq(3)
    expect(@eq_model3.reload.ordering).to eq(5)
  end
  it 'does not allow priority below number of elements' do
    all('.glyphicon-arrow-down').last.click
    expect(@eq_model.reload.ordering).to eq(1)
    expect(@eq_model2.reload.ordering).to eq(3)
    expect(@eq_model3.reload.ordering).to eq(5)
  end
end
