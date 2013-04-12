require 'redmine'
 
Redmine::Plugin.register :single_auth do
  name 'Single authentification plugin'
  author 'Pitin Vladimir Vladimirovich'
  author_url 'http://pitin.su'
  url 'http://github.com/AdamLantos/redmine_http_auth' if respond_to?(:url)
  description 'A plugin for doing single one authentification and synhronize users and groups with LDAP'
  version '1.0'

  settings :partial => 'settings/single_auth_settings',
    :default => {
      'enable' => 'true',
      'server_env_var' => 'REMOTE_USER',
      'lookup_mode' => 'login',
      'auto_registration' => 'true',
      'sync_users_from_ldap' => 'true',
      'sync_groups_from_ldap' => 'true',
      'ldap_rm_group_name_attr' => 'displayname',
      'keep_sessions' => 'false',
      'sync_groups_by_ass' => 'false'
    }
	
	delete_menu_item :account_menu, :login
	delete_menu_item :account_menu, :my_account
	#delete_menu_item :account_menu, :logout
	
	menu :account_menu, :my_name, { :controller => 'my', :action => 'account' }, :caption => Proc.new { User.current.name },  :if => Proc.new { User.current.logged? }
end

Rails.application.config.to_prepare do
  #include our code
  ApplicationController.send(:include, ApplicationControllerPatch)
  Group.send(:include, AutoFieldsGroupPatch)
end

require 'single_auth/view_hooks'

