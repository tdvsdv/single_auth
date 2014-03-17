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
      'server_env_var' => 'REMOTE_USER',
      }
end

Rails.application.config.to_prepare do
  ApplicationController.send(:include, SingleAuth::ApplicationControllerPatch)
  AccountController.send(:include, SingleAuth::AccountControllerPatch)
end

require 'single_auth/view_hooks'

