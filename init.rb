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
      # timeout before logging inactive user out, in seconds
      'logout_timeout' => 2*60,
      #:auto_logout_cookie_name => 'autologout',
      'intranet_domains' => ['rm.prp.ru', 'rm.local', 'redmine.local'],
      'token_valid_time' => 6*60,
      'screensaver_timeout' => 30,
      'sms_domain' => 'http://test.sender.prp.ru',
      'sms_sub_url' => '/api/send/sms',
      'sms_bot_login' => 'redmine',
      'sms_bot_password' => 'passw0rd'
      }
end

Rails.application.config.to_prepare do
  ApplicationController.send(:include, SingleAuth::ApplicationControllerPatch)
  AccountController.send(:include, SingleAuth::AccountControllerPatch)
  User.send(:include, SingleAuth::UserPatch)
  Object.send(:include, SingleAuth::ObjectPatch)
  Token.send(:include, SingleAuth::TokenPatch)
  token_valid_time = Setting.plugin_single_auth[:token_valid_time] || Redmine::Plugin::registered_plugins[:single_auth].settings[:default][:token_valid_time]
  redef_without_warning(ROTP, :DEFAULT_INTERVAL, token_valid_time.to_i)
end

require 'single_auth/view_hooks'

