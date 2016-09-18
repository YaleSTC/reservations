# frozen_string_literal: true
require 'spec_helper'

describe 'Users', type: :feature do
  context 'can be banned' do
    shared_examples 'can ban other users' do
      it do
        visit user_path(@user)
        expect(page).to have_link 'Ban', href: ban_user_path(@user)
        click_link 'Ban'
        expect { @user.reload }.to change { @user.role }.to('banned')
      end
    end

    shared_examples 'cannot ban self' do
      it do
        me = current_user
        visit user_path(me)
        expect(page).not_to have_link 'Ban', href: ban_user_path(@user)
      end
    end

    shared_examples 'cannot ban other users' do
      it do
        visit user_path(@user)
        expect(page).not_to have_link 'Ban', href: ban_user_path(@user)
      end
    end

    context 'as superuser' do
      before { sign_in_as_user(@superuser) }
      after { sign_out }

      it_behaves_like 'can ban other users'
      it_behaves_like 'cannot ban self'
    end

    context 'as admin' do
      before { sign_in_as_user(@admin) }
      after { sign_out }

      it_behaves_like 'can ban other users'
      it_behaves_like 'cannot ban self'
    end

    context 'as checkout person' do
      before { sign_in_as_user(@checkout_person) }
      after { sign_out }

      it 'cannot ban other users' do
        visit user_path(@user)
        expect(page).not_to have_link 'Ban', href: ban_user_path(@user)
      end
    end
  end
end
