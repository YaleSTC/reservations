class Ability
  include CanCan::Ability

  def initialize(user)
    if user
      case user.view_mode
      when 'superuser'
        can :manage, :all
      when 'admin'
        can :manage, :all
        unless AppConfig.first.enable_renewals
          cannot :renew, Reservation
        end
        cannot :appoint, :superuser
        cannot :access, :rails_admin
        cannot [:destroy,:update], User, :role => 'superuser'
      when 'checkout'
        can :manage, Reservation
        cannot :archive, Reservation
        unless AppConfig.first.enable_renewals
          cannot :renew, Reservation
        end
        cannot :destroy, Reservation do |r|
           r.checked_out != nil
        end
        unless AppConfig.first.checkout_persons_can_edit
          cannot :update, Reservation
        end
        can [:read,:update,:find,:autocomplete_user_last_name], User
        if AppConfig.first.enable_new_users
          can [:create, :quick_new, :quick_create], User
        end
        can :read, EquipmentObject
        can :read, EquipmentModel
        if AppConfig.first.override_on_create
          can :override, :reservation_errors
        end
        if AppConfig.first.override_at_checkout
          can :override, :checkout_errors
        end
      when 'normal' || 'checkout'
        can [:update,:show], User, :id => user.id
        can :read, EquipmentModel
        can [:read,:create], Reservation, :reserver_id => user.id
        can :destroy, Reservation, :reserver_id => user.id, :checked_out => nil
        if AppConfig.first.enable_renewals
          can :renew, Reservation, :reserver_id => user.id
        end
        can :update_cart, :all
      when 'guest'
        can :read, EquipmentModel
        can :update_cart, :all
        if AppConfig.first.enable_new_users
          can :create, User
        end
      when 'banned'
        #cannot :create, Reservation
      end
      case user.role
      when 'superuser'
        can :change, :views
        can :view_as, :superuser
      when 'admin'
        can :change, :views
        cannot :view_as, :superuser
      end
      cannot :change, :views unless ['admin', 'superuser'].include?(user.role)
    else
      can :create, User
    end
  end
end
