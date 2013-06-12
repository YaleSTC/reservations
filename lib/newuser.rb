module NewUser
	def new_user
		if current_user and current_user.is_admin_in_adminmode?
       		@user = User.new
     	else
       		@user = User.new(User.search_ldap(session[:cas_user]))
       		@user.login = session[:cas_user] #default to current login
     	end
	end
end