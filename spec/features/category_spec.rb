require 'spec_helper'

describe 'Categories', type: :feature do
  describe 'creation' do
    before do
      sign_in_as_user @superuser
      visit new_category_path
    end
    it 'succeeds' do
      attrs = { name: 'CATEGORY', max_per_user: 1, max_checkout_length: 3,
                sort_order: 1, max_renewal_times: 2, max_renewal_length: 4,
                renewal_days_before_due: 5 }
      attrs.each { |attr, value| fill_in("category_#{attr}", with: value) }
      click_button 'Create Category'
      expect(Category.where(name: attrs[:name])).not_to be_empty
    end
  end
  describe 'editing' do
    let!(:cat) { FactoryGirl.create(:category) }
    before { sign_in_as_user @superuser }
    shared_examples 'can update' do |attr, value|
      it attr.to_s do
        visit edit_category_path(cat)
        fill_in("category_#{attr}", with: value)
        click_button 'Update Category'
        cat.reload
        expect(cat.send(attr)).to eq(value)
      end
    end
    ATTRS = { name: 'CATEGORY', max_per_user: 1, max_checkout_length: 3,
              sort_order: 1, max_renewal_times: 2, max_renewal_length: 4,
              renewal_days_before_due: 5 }.freeze
    ATTRS.each { |attr, value| it_behaves_like 'can update', attr, value }
  end
end
