require 'spec_helper'

shared_examples_for 'page success' do
  it { should respond_with(:success) }
  it { should_not set_the_flash }
end

shared_examples_for 'access denied' do
  it { should redirect_to(root_url) }
  it { should set_the_flash }
end

describe BlackoutsController do
  before(:all) {
    @app_config = FactoryGirl.create(:app_config)
  }
  before {
    @controller.stub(:first_time_user).and_return(:nil)
  }

  describe 'with admin' do
    before do
      @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
    end
    context 'GET index' do
      before do
        get:index
      end
      it_behaves_like 'page success'
      it { should render_template(:index) }
      it 'should assign @blackouts to all blackouts' do
        expect(assigns(:blackouts)).to eq(Blackout.all)
      end
    end
    context 'GET show' do
      before do
        get :show, id: FactoryGirl.create(:blackout)
      end
      it_behaves_like 'page success'
      it { should render_template(:show) }
      context 'single blackout' do
        it 'should not display a set' do
          expect(assigns(:blackout_set) == nil)
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
          assigns(:blackout_set).uniq.sort.should eq(@blackout_set.uniq.sort)
        end
        # the above code doesn't work; i'm too much of an rspec newbie
      end
    end
    context 'GET new' do
      before do
        get :new
      end
      it_behaves_like 'page success'
      it { should render_template(:new) }
    end
    context 'GET new_recurring' do
      before do
        get :new_recurring
      end
      it_behaves_like 'page success'
      it { should render_template(:new_recurring) }
    end
    context 'GET edit' do
      before do
        get :edit, id: FactoryGirl.create(:blackout)
      end
      it_behaves_like 'page success'
      it { should render_template(:edit) }
    end
    context 'POST create_recurring' do
      context 'with correct params' do
        before do
          @new_set_id = Blackout.last ? Blackout.last.id + 1 : 0
          @attributes = FactoryGirl.attributes_for(:blackout, days: ["1",""])
          post :create_recurring, blackout: @attributes
        end
        it 'should create a set' do
          Blackout.where(set_id: @new_set_id).should_not be_empty
        end
        it { should redirect_to(blackouts_path) }
        it { should set_the_flash }
      end
      context 'with incorrect params' do
        before do
          request.env["HTTP_REFERER"] = "where_i_came_from"
          @attributes = FactoryGirl.attributes_for(:blackout, days: [""])
          post :create_recurring, blackout: @attributes
        end
        it { should set_the_flash }
        it { should redirect_to("where_i_came_from") }
      end
    end
    context 'POST create' do
      context 'with correct params' do
        before do
          @attributes = FactoryGirl.attributes_for(:blackout)
          post :create, blackout: @attributes
        end
        it 'should create the new blackout' do
          Blackout.find(assigns(:blackout)).should_not be_nil
        end
        it 'should pass the correct params' do
          assigns(:blackout)[:notice].should eq(@attributes[:notice])
          assigns(:blackout)[:start_date].should eq(@attributes[:start_date])
          assigns(:blackout)[:end_date].should eq(@attributes[:end_date])
          assigns(:blackout)[:blackout_type].should eq(@attributes[:blackout_type])
        end
        it { should redirect_to(blackout_path(assigns(:blackout))) }
        it { should set_the_flash }
      end
      context 'with incorrect params' do
        before do
          @attributes = FactoryGirl.attributes_for(:blackout)
          @attributes[:end_date] = Date.yesterday
          post :create, blackout: @attributes
        end
        it { should render_template(:new) }
      end
    end
    context 'PUT update' do
      context 'single blackout' do
        before do
          @new_attributes = FactoryGirl.attributes_for(:blackout)
          @new_attributes[:notice] = "New Message!!"
          put :update, id: FactoryGirl.create(:blackout), blackout: @new_attributes
        end
        it 'updates the blackout' do
          assigns(:blackout)[:notice].should eq(@new_attributes[:notice])
        end
      end
      context 'recurring blackout' do
        before do
          @new_attributes = FactoryGirl.attributes_for(:blackout)
          @new_attributes[:notice] = "New Message!!"
          put :update, id: FactoryGirl.create(:blackout, set_id: 1), blackout: @new_attributes
        end
        it 'updates the blackout' do
          assigns(:blackout)[:notice].should eq(@new_attributes[:notice])
        end
        it 'sets the set_id to nil' do
          assigns(:blackout)[:set_id].should be_nil
        end
      end
    end
    context 'DELETE destroy' do
      before do
        delete :destroy, id: FactoryGirl.create(:blackout)
      end
      it 'should delete the blackout' do
        Blackout.where(id:  assigns(:blackout)[:id]).should be_empty
      end
      it { should redirect_to(blackouts_path) }
    end
    context 'DELETE destroy recurring' do
      before do
        #create an extra instance to test that the whole set was deleted
        @extra = FactoryGirl.create(:blackout, set_id: 1)
        delete :destroy_recurring, id: FactoryGirl.create(:blackout, set_id: 1)
      end
      it 'should delete the whole set' do
        Blackout.where(set_id: @extra[:set_id]).should be_empty
      end
      it { should set_the_flash }
      it { should redirect_to(blackouts_path) }
    end
  end
  context 'is not admin' do
    before do
      @controller.stub(:current_user).and_return(FactoryGirl.create(:user))
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
