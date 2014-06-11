class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    case user.view_mode
		when 'admin'
			can :manage, :all
		when 'checkout'
			can :manage, Reservation
			can :read, User
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
		when 'banned'
			cannot :create, :reservation
	end
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user 
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. 
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
