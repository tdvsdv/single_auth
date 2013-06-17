module ApplicationControllerPatch
  unloadable

  def self.included(base)
    base.send(:include, ClassMethods)
	
    base.class_eval do
      #avoid infinite recursion in development mode on subsequent requests
      #alias_method :find_current_user, :find_current_user_without_httpauth if method_defined? 'find_current_user_without_httpauth'
      #alias_method_chain(:find_current_user, :httpauth)
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
			if Setting.plugin_single_auth['enable'] != "true" or session[:logout_was]
				return current_user 
			else
				remote_username=request.env[Setting.plugin_single_auth['server_env_var']]
				
				#return if the user has not been changed behind the session
				#return current_user unless session_changed? current_user, remote_username

				#log out current logged in user
				#reset_session
				
				#flash[:error]="sadasdasd";
				if current_user.nil?
					#flash[:error]="ssssssssss"+session[:user_id].to_s;
					if not remote_username.nil?
						try_login remote_username
					else
						return current_user 
					end
				else
					current_user
				end
			end
		end	

	    def add_user_by_ldap_info(remote_username)
			@auth_source ||= get_auth_source
			@ldap_conn ||= get_ldap_conn			
			new_user = User.new
			filter = Net::LDAP::Filter.eq(@auth_source.attr_login, remote_username)
			@ldap_conn.search(:base => @auth_source.base_dn, :filter => filter) do |entry|
				new_user.login=remote_username
				new_user.firstname=entry[@auth_source.attr_firstname].first.to_s
				new_user.lastname=entry[@auth_source.attr_lastname].first.to_s
				new_user.mail=entry[@auth_source.attr_mail].first.to_s
				new_user.language=Setting.default_language
				new_user.mail_notification=Setting.default_notification_option	
				end
			if new_user.save
				User.active.find_by_login remote_username
			end
	    end		
		
		def try_login remote_username	
			user=User.find_by_login remote_username	
			if user.nil?
				if Setting.plugin_single_auth['sync_users_from_ldap'] == 'true'
					add_user_by_ldap_info remote_username
				end
			else
				user
			end
			
			if do_login(user)
				make_user_ldap_sync(user, remote_username)
				make_group_ldap_sync(user, remote_username)
				make_group_sync_by_ass(user, remote_username) 
			end
			
			user
		end
		
	    def make_user_ldap_sync(user, username)
			if Setting.plugin_single_auth['sync_users_from_ldap'] == 'true'
				@auth_source ||= get_auth_source
				@ldap_conn ||= get_ldap_conn
				filter = Net::LDAP::Filter.eq(@auth_source.attr_login, username)
				@ldap_conn.search(:base => @auth_source.base_dn, :filter => filter) do |entry|	
					user.mail=entry[@auth_source.attr_mail].first.to_s
					user.firstname=entry[@auth_source.attr_firstname].first.to_s
					user.lastname=entry[@auth_source.attr_lastname].first.to_s
					user.save
					end
			end
	    end	

	    def make_group_ldap_sync(user, username)
			if Setting.plugin_single_auth['sync_groups_from_ldap'] == 'true'
				@auth_source ||= get_auth_source
				@ldap_conn ||= get_ldap_conn
				user_dn = get_user_dn(username)
					
				filterA = Net::LDAP::Filter.eq('member', user_dn)
				filterB = Net::LDAP::Filter.eq('objectclass', 'group')
				filter=filterA & filterB;

				@ldap_conn.search(:base => @auth_source.base_dn, :filter => filter) { |entry|
					group = Group.find_or_create_by_lastname(entry['cn'].first.to_s)
					if ! group.users.include?(user)
						group.users << user	
						group.save
					end
					}	
			end
		
	    end	
		
		def get_user_dn(username)
			@auth_source ||= get_auth_source
			@ldap_conn ||= get_ldap_conn	

			user_dn=nil
			filter = Net::LDAP::Filter.eq(@auth_source.attr_login, username)
				@ldap_conn.search(:base => @auth_source.base_dn, :filter => filter) { |entry|
					user_dn=entry['distinguishedname'].first.to_s 
					}	
			user_dn
		end

	    def add_or_rem_from_group (group_id, flag, user)
			if(group_id!=0)
				group=Group.find_by_id(group_id)
				if(flag)
					if !group.users.include?(user)
						group.users << user	
						group.save
					end
				else
					if group.users.include?(user)
						group.users.delete(user)
					end
				end
			end  
	    end		
		
	    def make_group_sync_by_ass(user, username)
			if Setting.plugin_single_auth['sync_groups_by_ass'] == 'true'
				@auth_source ||= get_auth_source
				@ldap_conn ||= get_ldap_conn
				
				user_dn = get_user_dn(username)
					
				filterA = Net::LDAP::Filter.eq('member', user_dn)
				filterB = Net::LDAP::Filter.eq('objectclass', 'group')
				filter=filterA & filterB;
				users_group_uids = []
				@ldap_conn.search(:base => @auth_source.base_dn, :filter => filter) { |entry|
					users_group_uids.push(entry.objectGUID.first.unpack("H*").first.to_s)
					}	

				ldapgroups=Ldapgroup.find(:all, :order => "group_id ASC")
				group_id=0
				flag=true
				@tttt="";
				ldapgroups.each { |gr|
					if gr.group_id!=group_id
						if group_id!=0		
							add_or_rem_from_group(group_id, flag, user)					
							flag=true if ! flag
						end
						group_id=gr.group_id
					end
					
					if users_group_uids.include?(gr.ldap_group_name)
						flag = flag && true
					else
						flag = flag && false
					end				
					}

				add_or_rem_from_group(group_id, flag, user)
			end
	    end		
		
		def do_login(user)
		  if (user && user.is_a?(User))
			session[:user_id] = user.id
			session[:single_auth] = true
			user.update_attribute(:last_login_on, Time.now)
			User.current = user
		  else
			return nil
		  end
		end		
	end
end

