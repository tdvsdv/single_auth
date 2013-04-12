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
=begin  
  def user_attributes
    ['login', 'mail', 'firstname', 'lastname']
  end

  def use_email?
    Setting.plugin_redmine_http_auth['lookup_mode'] == 'mail'
  end

  def set_default_attributes(user)
    user_attributes.each do |attr|
      user.send(attr + "=", (get_attribute_value attr))
    end
  end

  def set_readonly_attributes(user)
    user_attributes.each do |attr|
      user.send(attr + "=", (get_attribute_value attr)) if readonly_attribute? attr
    end
  end

  def remote_user
    request.env[Setting.plugin_redmine_http_auth['server_env_var']]
    #remote_user=request.env[Setting.plugin_redmine_http_auth['server_env_var']]
    #remote_user_arr=remote_user.split('@');
    #return remote_user_arr[0];
  end

  def readonly_attribute?(attribute_name)
    if remote_user_attribute? attribute_name
      true
    else
      conf = Setting.plugin_redmine_http_auth['readonly_attribute']
      if conf.nil? || !conf.has_key?(attribute_name)
        false
      else
        conf[attribute_name] == "true"
      end
    end
  end

  private
  def remote_user_attribute?(attribute_name)
    (attribute_name == "login" && !use_email?) || (attribute_name == "mail" && use_email?)
  end

  def get_attribute_value(attribute_name)
    if remote_user_attribute? attribute_name
      remote_user
    else
      conf = Setting.plugin_redmine_http_auth['attribute_mapping']
      if conf.nil? || !conf.has_key?(attribute_name)
        nil
      else
        request.env[conf[attribute_name]]
      end
    end
  end
=end
end
