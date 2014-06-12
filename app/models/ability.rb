class Ability
  include CanCan::Ability

  def initialize(user)
   
    case user.view_mode
		when 'admin'
			can :manage, :all
		when 'checkout'
			can :manage, Reservation
			unless AppConfig.first.checkout_persons_can_edit
				cannot :update, Reservation
			end
			can :read, User
			can :update, User
			can :create, User
			can :read, Category
			can :read, EquipmentObject
			can :read, EquipmentModel
			if AppConfig.first.override_on_create
				can :override, :reservation_errors
			end
			if AppConfig.first.override_at_checkout
				can :override, :checkout_errors
			end
		when 'normal' || 'checkout'
			can :read, User, :id => user.id
			can :read, Reservation, :reserver_id => user.id
			can :create, Reservation, :reserver_id => user.id
			can :destroy, Reservation, :reserver_id => user.id, :checked_out => nil
			can :read, Reservation, :reserver_id => user.id
		when 'banned'
			cannot :create, :reservation
	end
    
  end
end
