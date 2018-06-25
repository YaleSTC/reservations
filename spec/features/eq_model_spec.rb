# frozen_string_literal: true
require 'spec_helper'

describe 'Equipment Model views', type: :feature do
  context 'show view' do
    context 'pending reservations' do
      before(:each) do
        4.times do
          FactoryGirl.create :equipment_item, equipment_model: @eq_model
        end
        FactoryGirl.build(:checked_in_reservation,
                          equipment_model: @eq_model).save(validate: false)

        @today_res =
          FactoryGirl.create :valid_reservation,
                             equipment_model: @eq_model,
                             start_date: Time.zone.today
        @pending_res_1 =
          FactoryGirl.create :valid_reservation,
                             equipment_model: @eq_model,
                             start_date: Time.zone.today + 1.day,
                             due_date: Time.zone.today + 3.days
        @pending_res_2 =
          FactoryGirl.create :valid_reservation,
                             equipment_model: @eq_model,
                             start_date: Time.zone.today + 1.day,
                             due_date: Time.zone.today + 3.days
        @far_future_res =
          FactoryGirl.create :valid_reservation,
                             equipment_model: @eq_model,
                             start_date: Time.zone.today + 9.days,
                             due_date: Time.zone.today + 10.days
      end

      shared_examples 'can see pending reservations' do
        it 'displays the correct counts and links' do
          num_divs =
            page.all(:css, 'section#pending_reservations .giant-numbers div')
          expect(num_divs[0].text).to eq('1')
          expect(num_divs[1].text).to eq('2')
          expect(page).to have_link @today_res.id.to_s,
                                    href: reservation_path(@today_res)
          expect(page).to have_link @pending_res_1.id.to_s,
                                    href: reservation_path(@pending_res_1)
          expect(page).to have_link @pending_res_2.id.to_s,
                                    href: reservation_path(@pending_res_2)
          expect(page).not_to have_link @far_future_res.id.to_s,
                                        href: reservation_path(@far_future_res)
        end
      end

      shared_examples 'cannot see pending reservations' do
        it 'does not display the section' do
          expect(page).not_to have_content 'section#pending_reservations'
        end
      end

      context 'as superuser' do
        before do
          sign_in_as_user @superuser
          visit equipment_model_path(@eq_model)
        end
        after { sign_out }

        it_behaves_like 'can see pending reservations'
      end

      context 'as admin' do
        before do
          sign_in_as_user @admin
          visit equipment_model_path(@eq_model)
        end
        after { sign_out }

        it_behaves_like 'can see pending reservations'
      end

      context 'as checkout person' do
        before do
          sign_in_as_user @checkout_person
          visit equipment_model_path(@eq_model)
        end
        after { sign_out }

        it_behaves_like 'cannot see pending reservations'
      end

      context 'as patron' do
        before do
          sign_in_as_user @user
          visit equipment_model_path(@eq_model)
        end
        after { sign_out }

        it_behaves_like 'cannot see pending reservations'
      end

      context 'as guest' do
        before { visit equipment_model_path(@eq_model) }
        it_behaves_like 'cannot see pending reservations'
      end
    end
  end
  describe 'creation' do
    let!(:cat) { FactoryGirl.create(:category) }
    before do
      sign_in_as_user @superuser
      visit new_equipment_model_path
    end
    it 'succeeds' do
      attrs = { name: 'EQ MODEL', description: 'DESC', late_fee: 5,
                replacement_fee: 10, late_fee_max: 15, max_per_user: 1,
                max_checkout_length: 3, max_renewal_times: 2,
                max_renewal_length: 4, renewal_days_before_due: 5 }
      select(cat.name, from: 'equipment_model_category_id')
      attrs.each do |attr, value|
        fill_in("equipment_model_#{attr}", with: value)
      end
      click_button 'Create Equipment model'
      expect(EquipmentModel.where(name: attrs[:name])).not_to be_empty
    end
  end
  describe 'editing' do
    let!(:model) { FactoryGirl.create(:equipment_model) }
    before { sign_in_as_user @superuser }
    shared_examples 'can update' do |attr, value|
      it attr.to_s do
        visit edit_equipment_model_path(model)
        fill_in("equipment_model_#{attr}", with: value)
        click_button 'Update Equipment model'
        model.reload
        expect(model.send(attr)).to eq(value)
      end
    end
    ATTRS = { name: 'EQ MODEL', description: 'DESC', late_fee: 5,
              replacement_fee: 10, late_fee_max: 15, max_per_user: 1,
              max_checkout_length: 3, max_renewal_times: 2,
              max_renewal_length: 4, renewal_days_before_due: 5 }.freeze
    ATTRS.each { |attr, value| it_behaves_like 'can update', attr, value }
  end
  # TODO: 
  #   - multiple deactivate buttons
  #   - currently doesn't pass right params?
  #describe 'deactivation' do
  #  let!(:model) { FactoryGirl.create(:equipment_model) }
  #  before { sign_in_as_user @superuser }
  #  it 'succeeds' do
  #    visit equipment_model_path(model)
  #    save_and_open_page
  #    expect(page).to have_content 'deactivated'
  #  end
  #  context 'with items' do
  #    it 'also deactivates the items' do
  #    end
  #  end
  #end
end
