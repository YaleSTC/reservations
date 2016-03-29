# frozen_string_literal: true
require 'spec_helper'

describe OrderingRepairer do
  it 'makes unique within a category' do
    category = FactoryGirl.create(:category)
    model = FactoryGirl.create(:equipment_model,
                               category: category, ordering: 1)
    FactoryGirl.create(:equipment_model,
                       category: category, ordering: 1)
    expect { OrderingRepairer.new(category).repair }
      .to change { model.reload.ordering }.from(1).to(2)
  end
  it 'makes be -1 if deactivated' do
    category = FactoryGirl.create(:category)
    model = FactoryGirl.create(:equipment_model,
                               category: category,
                               ordering: 1,
                               deleted_at: Time.zone.now)
    expect { OrderingRepairer.new(category).repair }
      .to change { model.reload.ordering }.from(1).to(-1)
  end
  it 'allows be a duplicate if deactivated' do
    category = FactoryGirl.create(:category)
    FactoryGirl.create(:equipment_model,
                       category: category,
                       ordering: -1,
                       deleted_at: Time.zone.now)
    model2 = FactoryGirl.create(:equipment_model,
                                category: category,
                                ordering: -1,
                                deleted_at: Time.zone.now)
    expect { OrderingRepairer.new(category).repair }
      .not_to change { model2.reload.ordering }
  end
  it 'makes not under bounds' do
    category = FactoryGirl.create(:category)
    FactoryGirl.create(:equipment_model, category: category, ordering: 1)
    model2 = FactoryGirl.create(:equipment_model,
                                category: category, ordering: -1)
    expect { OrderingRepairer.new(category).repair }
      .to change { model2.reload.ordering }.from(-1).to(2)
  end
  it 'makes not over bounds' do
    category = FactoryGirl.create(:category)
    FactoryGirl.create(:equipment_model,
                       category: category,
                       ordering: 1)
    FactoryGirl.create(:equipment_model,
                       category: category,
                       ordering: 2)
    model3 = FactoryGirl.create(:equipment_model,
                                category: category,
                                ordering: 4)
    expect { OrderingRepairer.new(category).repair }
      .to change { model3.reload.ordering }.from(4).to(3)
  end
end
