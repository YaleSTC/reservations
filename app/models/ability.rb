class Ability
  include CanCan::Ability

  def initialize(user)
    if user
      case user.view_mode
	    	#when 'superuser'
		  	#can :manage, :all
	  	when 'admin'
		  	can :manage, :all
		  	#cannot :appoint, :superuser
		  	#cannot :manage, Admin
		  when 'checkout'
			  can :manage, Reservation
        cannot :destroy, Reservation do |r|
           r.checked_out != nil
        end
			  unless AppConfig.first.checkout_persons_can_edit
		  		cannot :update, Reservation
		  	end
			  can :read, User
			  can :update, User
			  can :create, User
			  can :read, EquipmentObject
			  can :read, EquipmentModel
		  	if AppConfig.first.override_on_create
	  			can :override, :reservation_errors
  			end
			  if AppConfig.first.override_at_checkout
		  		can :override, :checkout_errors
	  		end
  		when 'normal' || 'checkout'
			  can [:create,:update,:read], User, :id => user.id
        can :read, EquipmentModel
			  can :read, Reservation, :reserver_id => user.id
			  can :create, Reservation, :reserver_id => user.id
		  	can :destroy, Reservation, :reserver_id => user.id, :checked_out => nil
  		when 'banned'
			  #cannot :create, Reservation
	    end
    end  
  end
end
