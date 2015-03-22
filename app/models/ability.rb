class Ability
  include CanCan::Ability

  def initialize(user) # rubocop:disable all
    if user
      case user.view_mode
      when 'superuser'
        can :manage, :all
      when 'admin'
        can :manage, :all
        cannot :renew, Reservation unless AppConfig.check(:enable_renewals)
        cannot :appoint, :superuser
        cannot :access, :rails_admin
        cannot [:destroy, :update], User, role: 'superuser'
      when 'checkout'
        can :manage, Reservation
        cannot :archive, Reservation
        cannot :renew, Reservation unless AppConfig.check(:enable_renewals)
        cannot :destroy, Reservation do |r|
          !r.checked_out.nil?
        end
        unless AppConfig.check(:checkout_persons_can_edit)
          cannot :update, Reservation
        end
        can [:read, :update, :find, :autocomplete_user_last_name], User
        if AppConfig.check(:enable_new_users)
          can [:create, :quick_new, :quick_create], User
        end
        can :read, EquipmentItem
        can :read, EquipmentModel
        can :override, :reservation_errors if AppConfig.get(:override_on_create)
        can :override, :checkout_errors if AppConfig.get(:override_at_checkout)
      when 'normal' || 'checkout'
        can [:update, :show], User, id: user.id
        can :read, EquipmentModel
        can [:read, :create], Reservation, reserver_id: user.id
        can :destroy, Reservation, reserver_id: user.id, checked_out: nil
        if AppConfig.check(:enable_renewals)
          can :renew, Reservation, reserver_id: user.id
        end
        can :update_cart, :all
        can :update_index_dates, Reservation
        can :view_all_dates, Reservation
      when 'guest'
        # rubocop:disable BlockNesting
        if AppConfig.check(:enable_guests)
          can :read, EquipmentModel
          can :empty_cart, :all
          can :update_cart, :all
          can :create, User if AppConfig.check(:enable_new_users)
        end
        # rubocop:enable BlockNesting
      when 'banned'
        # cannot :create, Reservation
      end
      case user.role
      when 'superuser'
        can :change, :views
        can :view_as, :superuser
      when 'admin'
        can :change, :views
        cannot :view_as, :superuser
      end
      cannot :change, :views unless %w(admin superuser).include?(user.role)
    else
      can :create, User
    end
  end
end
