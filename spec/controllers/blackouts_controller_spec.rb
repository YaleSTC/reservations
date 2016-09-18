# frozen_string_literal: true
require 'spec_helper'

shared_examples_for 'page success' do
  it { is_expected.to respond_with(:success) }
  it { is_expected.not_to set_flash }
end

shared_examples_for 'access denied' do
  it { is_expected.to redirect_to(root_url) }
  it { is_expected.to set_flash }
end

describe BlackoutsController, type: :controller do
  before(:each) { mock_app_config }

  describe 'with admin' do
    before do
      sign_in FactoryGirl.create(:admin)
    end
    context 'GET index' do
      before do
        get :index
      end
      it_behaves_like 'page success'
      it { is_expected.to render_template(:index) }
      it 'should assign @blackouts to all blackouts' do
        expect(assigns(:blackouts)).to eq(Blackout.all)
      end
    end
    context 'GET show' do
      before do
        get :show, id: FactoryGirl.create(:blackout)
      end
      it_behaves_like 'page success'
      it { is_expected.to render_template(:show) }
      context 'single blackout' do
        it 'should not display a set' do
          expect(assigns(:blackout_set).nil?)
        end
      end
    end
    context 'GET show' do
      before do
        @blackout = FactoryGirl.create(:blackout, set_id: 1)
        @blackout_set = Blackout.where(set_id: 1)
        get :show, id: @blackout
      end
      it_behaves_like 'page success'
      context 'recurring blackout' do
        it 'should display the correct set' do
          expect(assigns(:blackout_set).uniq.sort).to\
            eq(@blackout_set.uniq.sort)
        end
        # the above code doesn't work; i'm too much of an rspec newbie
      end
    end
    context 'GET new' do
      before do
        get :new
      end
      it_behaves_like 'page success'
      it { is_expected.to render_template(:new) }
    end
    context 'GET new_recurring' do
      before do
        get :new_recurring
      end
      it_behaves_like 'page success'
      it { is_expected.to render_template(:new_recurring) }
    end
    context 'GET edit' do
      before do
        get :edit, id: FactoryGirl.create(:blackout)
      end
      it_behaves_like 'page success'
      it { is_expected.to render_template(:edit) }
    end
    context 'POST create_recurring' do
      context 'with correct params' do
        before do
          @new_set_id = Blackout.last ? Blackout.last.id + 1 : 0
          @attributes = FactoryGirl.attributes_for(:blackout, days: ['1', ''])
          post :create_recurring, blackout: @attributes
        end
        it 'should create a set' do
          expect(Blackout.where(set_id: @new_set_id)).not_to be_empty
        end
        it { is_expected.to redirect_to(blackouts_path) }
        it { is_expected.to set_flash }
      end
      context 'with incorrect params' do
        before do
          request.env['HTTP_REFERER'] = 'where_i_came_from'
          @attributes = FactoryGirl.attributes_for(:blackout, days: [''])
          post :create_recurring, blackout: @attributes
        end
        it { is_expected.to set_flash }
        it { is_expected.to render_template('new_recurring') }
      end
      context 'with conflicting reservation' do
        before do
          @res = FactoryGirl.create(:valid_reservation,
                                    due_date: Time.zone.today + 1.day)
          @attributes = FactoryGirl.attributes_for(
            :blackout, days: [(Time.zone.today + 1.day).wday.to_s]
          )
          post :create_recurring, blackout: @attributes
        end

        it { is_expected.to set_flash }
        it { is_expected.to render_template('new_recurring') }
        it 'should not save the blackouts' do
          expect { post :create_recurring, blackout: @attributes }.not_to \
            change { Blackout.all.count }
        end
      end
    end

    context 'POST create' do
      shared_examples_for 'creates blackout' do |attributes|
        before { post :create, blackout: attributes }

        it 'should create the new blackout' do
          expect(Blackout.find(assigns(:blackout).id)).not_to be_nil
        end
        it 'should pass the correct params' do
          expect(assigns(:blackout)[:notice]).to eq(attributes[:notice])
          expect(assigns(:blackout)[:start_date]).to\
            eq(attributes[:start_date])
          expect(assigns(:blackout)[:end_date]).to eq(attributes[:end_date])
          expect(assigns(:blackout)[:blackout_type]).to\
            eq(attributes[:blackout_type])
        end
        it { is_expected.to redirect_to(blackout_path(assigns(:blackout))) }
        it { is_expected.to set_flash }
      end

      shared_examples_for 'does not create blackout' do |attributes|
        before { post :create, blackout: attributes }

        it { is_expected.to set_flash }
        it { is_expected.to render_template(:new) }
        it 'should not save the blackout' do
          expect { post :create, blackout: attributes }.not_to\
            change { Blackout.all.count }
        end
      end

      context 'with correct params' do
        attributes = FactoryGirl.attributes_for(:blackout)

        it_behaves_like 'creates blackout', attributes
      end

      context 'with overlapping archived reservation' do
        before do
          FactoryGirl.create(:archived_reservation,
                             start_date: Time.zone.today + 1.day,
                             due_date: Time.zone.today + 3.days)
        end

        attributes =
          FactoryGirl.attributes_for(:blackout,
                                     start_date: Time.zone.today,
                                     end_date: Time.zone.today + 2.days)

        it_behaves_like 'creates blackout', attributes
      end

      context 'with overlapping missed reservation' do
        before do
          FactoryGirl.create(:missed_reservation,
                             start_date: Time.zone.today + 1.day,
                             due_date: Time.zone.today + 3.days)
        end

        attributes =
          FactoryGirl.attributes_for(:blackout,
                                     start_date: Time.zone.today,
                                     end_date: Time.zone.today + 2.days)

        it_behaves_like 'creates blackout', attributes
      end

      context 'with incorrect params' do
        attributes =
          FactoryGirl.attributes_for(:blackout,
                                     end_date: Time.zone.today - 1.day)

        it_behaves_like 'does not create blackout', attributes
      end

      context 'with conflicting reservation start date' do
        before do
          FactoryGirl.create(:valid_reservation,
                             start_date: Time.zone.today + 1.day,
                             due_date: Time.zone.today + 3.days)
        end

        attributes =
          FactoryGirl.attributes_for(:blackout,
                                     start_date: Time.zone.today,
                                     end_date: Time.zone.today + 2.days)

        it_behaves_like 'does not create blackout', attributes
      end

      context 'with conflicting reservation due date' do
        before do
          FactoryGirl.create(:valid_reservation,
                             start_date: Time.zone.today,
                             due_date: Time.zone.today + 2.days)
        end

        attributes =
          FactoryGirl.attributes_for(:blackout,
                                     start_date: Time.zone.today + 1.day,
                                     end_date: Time.zone.today + 3.days)

        it_behaves_like 'does not create blackout', attributes
      end
    end

    context 'PUT update' do
      context 'single blackout' do
        before do
          @new_attributes = FactoryGirl.attributes_for(:blackout)
          @new_attributes[:notice] = 'New Message!!'
          put :update, id: FactoryGirl.create(:blackout),
                       blackout: @new_attributes
        end
        it 'updates the blackout' do
          expect(assigns(:blackout)[:notice]).to eq(@new_attributes[:notice])
        end
      end
      context 'recurring blackout' do
        before do
          @new_attributes = FactoryGirl.attributes_for(:blackout)
          @new_attributes[:notice] = 'New Message!!'
          put :update, id: FactoryGirl.create(:blackout, set_id: 1),
                       blackout: @new_attributes
        end
        it 'updates the blackout' do
          expect(assigns(:blackout)[:notice]).to eq(@new_attributes[:notice])
        end
        it 'sets the set_id to nil' do
          expect(assigns(:blackout)[:set_id]).to be_nil
        end
      end
    end
    context 'DELETE destroy' do
      before do
        delete :destroy, id: FactoryGirl.create(:blackout)
      end
      it 'should delete the blackout' do
        expect(Blackout.where(id:  assigns(:blackout)[:id])).to be_empty
      end
      it { is_expected.to redirect_to(blackouts_path) }
    end
    context 'DELETE destroy recurring' do
      before do
        # create an extra instance to test that the whole set was deleted
        @extra = FactoryGirl.create(:blackout, set_id: 1)
        delete :destroy_recurring, id: FactoryGirl.create(:blackout, set_id: 1)
      end
      it 'should delete the whole set' do
        expect(Blackout.where(set_id: @extra[:set_id])).to be_empty
      end
      it { is_expected.to set_flash }
      it { is_expected.to redirect_to(blackouts_path) }
    end
  end
  context 'is not admin' do
    before do
      sign_in FactoryGirl.create(:user)
      @blackout = FactoryGirl.create(:blackout)
      @attributes = FactoryGirl.attributes_for(:blackout)
    end

    context 'GET index' do
      before do
        get :index
      end
      it_behaves_like 'access denied'
    end
    context 'GET show' do
      before do
        get :show, id: @blackout
      end
      it_behaves_like 'access denied'
    end
    context 'POST create' do
      before do
        post :create, blackout: @attributes
      end
      it_behaves_like 'access denied'
    end
    context 'PUT update' do
      before do
        put :update, id: @blackout
      end
      it_behaves_like 'access denied'
    end
    context 'POST create recurring' do
      before do
        post :create_recurring, blackout: @attributes
      end
      it_behaves_like 'access denied'
    end
    context 'DELETE destroy' do
      before do
        delete :destroy, id: @blackout
      end
      it_behaves_like 'access denied'
    end
    context 'DELETE destroy recurring' do
      before do
        delete :destroy_recurring, id: @blackout
      end
      it_behaves_like 'access denied'
    end
  end
end
