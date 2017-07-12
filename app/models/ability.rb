# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    @user = user
    if user.nil?
      guest
      return
    end

    send(user.view_mode.to_sym)
    case user.role
    when 'superuser'
      can :change, :views
      can :view_as, :superuser
    when 'admin'
      can :change, :views
      cannot :view_as, :superuser
    end
    cannot :change, :views unless %w[admin superuser].include?(user.role)
  end

  def superuser
    can :manage, :all
    can :access, :rails_admin
    can :dashboard
  end

  def admin
    can :manage, :all
    cannot :renew, Reservation unless AppConfig.check(:enable_renewals)
    cannot :appoint, :superuser
    cannot :access, :rails_admin
    cannot %i[destroy update], User, role: 'superuser'
    cannot :run, :jobs
  end

  def checkout
    can :manage, Reservation
    cannot :archive, Reservation
    cannot :renew, Reservation unless AppConfig.check(:enable_renewals)
    cannot :destroy, Reservation do |r|
      !r.checked_out.nil?
    end
    unless AppConfig.check(:checkout_persons_can_edit)
      cannot :update, Reservation
    end
    can %i[read update find autocomplete_user_last_name], User
    if AppConfig.check(:enable_new_users)
      can %i[create quick_new quick_create], User
    end
    can :read, EquipmentItem
    can :override, :reservation_errors if AppConfig.get(:override_on_create)
    can :override, :checkout_errors if AppConfig.get(:override_at_checkout)
    normal
  end

  def normal
    can %i[update show], User, id: @user.id
    can :read, EquipmentModel
    can %i[read create], Reservation, reserver_id: @user.id
    can :destroy, Reservation, reserver_id: @user.id, checked_out: nil
    if AppConfig.check(:enable_renewals)
      can :renew, Reservation, reserver_id: @user.id
    end
    can :reload_catalog_cart, :all
    can :update_cart, :all
    can :update_index_dates, Reservation
    can :view_all_dates, Reservation
    can :view_detailed, EquipmentModel
    can :hide, Announcement
  end

  def guest
    return unless AppConfig.check(:enable_guests)
    can :read, EquipmentModel
    can :empty_cart, :all
    can :reload_catalog_cart, :all
    can :update_cart, :all
    can :create, User if AppConfig.check(:enable_new_users)
    can :hide, Announcement
  end

  def banned
    can :hide, Announcement
  end
end
