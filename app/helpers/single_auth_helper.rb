# require_dependency 'project'
# require_dependency 'principal'
# require_dependency 'user'

module SingleAuthHelper
	unloadable

	def get_auth_source
		auth_source = AuthSource.first
	end

	def get_ldap_conn
		auth_source = get_auth_source

		if auth_source.port == 0
			port = 389
		else
			port = auth_source.port
		end

		ldap = Net::LDAP.new :host => auth_source.host,
			 :port => port,
				:auth => {
					:method => :simple,
					:username => auth_source.account,
					:password => auth_source.account_password
				}
		return ldap
	end

  def set_auto_logout_cookie(user)
  	logout_timeout = Setting.plugin_single_auth[:logout_timeout] || Redmine::Plugin::registered_plugins[:single_auth].settings[:default]['logout_timeout']

  	token = Token.create(:user => user, :action => 'tfa_login')
  	cookie_options = {
    	:value => token.value,
    	:expires => logout_timeout.to_i.seconds.from_now,
    	:path => '/',
    	:secure => false,
    	:httponly => true
  	}

  	cookies[:autologout] = cookie_options
  	logger.debug "cookies[:autologout]=#{cookies[:autologout]}"
	end

end
