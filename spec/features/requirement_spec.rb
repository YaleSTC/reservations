require 'spec_helper'

describe 'Requirements', type: :feature do
  context 'as admin' do
    before { sign_in_as_user @admin }
    it 'can create' do
      model = FactoryGirl.create(:equipment_model)
      visit new_requirement_path
      attrs = { description: 'DESC', contact_name: 'Name',
                contact_info: 'info' }
      attrs.each do |attr, value|
        fill_in("requirement_#{attr}", with: value)
      end
      select(model.name, from: 'requirement_equipment_model_ids')
      click_button 'Create Requirement'
      model.reload
      expect(model.requirements).not_to be_empty
    end
    it 'can add a requirement to a user' do
      user = FactoryGirl.create(:user)
      req = FactoryGirl.create(:requirement)
      visit edit_user_path(user)
      select(req.description, from: 'user_requirement_ids')
      click_button 'Update User'
      user.reload
      expect(user.requirements).to include(req)
    end
  end
  context 'reservation creation' do
    let!(:req) { FactoryGirl.create(:requirement) }
    let!(:model) do
      FactoryGirl.create(:equipment_model_with_item, requirements: [req])
    end
    context 'satisifed requirement' do
      before do
        sign_in_as_user(FactoryGirl.create(:user, requirements: [req]))
      end
      it 'can add to cart' do
        visit equipment_model_path(model)
        expect(page).to have_link('Add to Cart')
      end
    end
    context 'has not satisifed requirement' do
      before do
        sign_in_as_user(FactoryGirl.create(:user))
      end
      it 'cannot add to cart' do 
        visit equipment_model_path(model)
        expect(page).to have_link('Not Qualified')
      end
    end
  end
end
