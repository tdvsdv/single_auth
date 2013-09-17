module ApplicationControllerPatch
  unloadable

  def self.included(base)
    base.send(:include, ClassMethods)
	
    base.class_eval do
		  include SingleAuthHelper
		  alias_method_chain :find_current_user, :ldap_single_auth
		  alias_method_chain :logout_user, :ldap_single_auth
    end
  end

	module ClassMethods

		def logout_user_with_ldap_single_auth
			logout_user_without_ldap_single_auth
			session[:logout_was] = true 
		end

		def find_current_user_with_ldap_single_auth
			current_user = find_current_user_without_ldap_single_auth
			if session[:logout_was]
				return current_user 
			else
				remote_username=request.env[Setting.plugin_single_auth['server_env_var']]
				
				if current_user.nil?
					if not remote_username.nil?
						try_login_by_remote_env remote_username
					else
						return current_user 
					end
				else
					current_user
				end
			end
		end	

		def try_login_by_remote_env(remote_username)
			user = User.active.find_by_login remote_username	
			Rails.logger.debug "ggggg #{remote_username}"
			if user.nil?		
				user = add_user_by_ldap_info(remote_username)
			end
			
			user if do_login(user)
		end

	  def add_user_by_ldap_info(remote_username)
			auth_source = get_auth_source
			if auth_source
				ldap_conn = get_ldap_conn	
				new_user = User.new
				filter = Net::LDAP::Filter.eq(auth_source.attr_login, remote_username)
				ldap_conn.search(:base => auth_source.base_dn, :filter => filter) do |entry|
						new_user.login=remote_username
						new_user.firstname=entry[auth_source.attr_firstname].first.to_s
						new_user.lastname=entry[auth_source.attr_lastname].first.to_s
						new_user.mail=entry[auth_source.attr_mail].first.to_s
						new_user.language=Setting.default_language
						new_user.mail_notification=Setting.default_notification_option	
					end

				if new_user.save
					new_user
				end
			end
	  end		
				
		def do_login(user)
		  if (user && user.is_a?(User))
				start_user_session(user)
				session[:single_auth] = true
				user.update_attribute(:last_login_on, Time.now)
				#User.current = user
		  else
				return nil
		  end
		end		
	end
end

