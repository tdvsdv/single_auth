require_dependency 'project'
require_dependency 'principal'
require_dependency 'user'

module SingleAuthHelper
	unloadable
 
	def get_auth_source
		auth_source=AuthSource.first
	end
 
	def get_ldap_conn
		auth_source=get_auth_source	
			
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

end
