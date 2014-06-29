module SingleAuth
  module ApplicationControllerPatch
    unloadable

    def self.included(base)
      base.send(:include, ClassMethods)

      base.class_eval do
        include SingleAuthHelper
        alias_method_chain :find_current_user, :ldap_single_auth
        alias_method_chain :logout_user, :ldap_single_auth

        append_before_filter :update_autologout_time
        before_filter :tfa_logout
      end
    end

    module ClassMethods

      def logout_user_with_ldap_single_auth
        user = User.current
        session[:was_tfa_login] = true if user.tfa_login
        user.logout_time = nil
        user.tfa_login = false
        user.save

        logout_user_without_ldap_single_auth
        session[:logout_was] = true

        Token.delete_all(["user_id = ? AND action = ?", User.current.id, 'tfa_login'])
      end

      def find_current_user_with_ldap_single_auth
        current_user = find_current_user_without_ldap_single_auth
        if current_user.nil? && request.env[Setting.plugin_single_auth['server_env_var']]
          unless session[:was_tfa_login]
            current_user = try_login_by_remote_env(request.env[Setting.plugin_single_auth['server_env_var']])
          end
        end
        current_user
      end

      def try_login_by_remote_env(remote_username)
        user = User.active.find_by_login remote_username
        if user.nil?
          user = add_user_by_ldap_info(remote_username)
        end

        user if !session[:logout_was] && do_login(user)
      end

      def add_user_by_ldap_info(remote_username)
        auth_source = get_auth_source
        new_user = nil
        if auth_source && auth_source.onthefly_register?
          filter = Net::LDAP::Filter.eq(auth_source.attr_login, remote_username)
          ldap_connection = get_ldap_conn
          ldap_connection.search(:base => auth_source.base_dn, :filter => filter) do |entry|
            if Redmine::Plugin.installed?(:ldap_users_sync)
              user_sync = LdapUsersSync::LdapSyncUser.new(self, ldap_connection, true)
              new_user = user_sync.update_or_create(entry, LdapUsersSync::LdapSyncUser.object_guid_to_s(entry['objectGUID']))
            else
              new_user = User.create( { :login => remote_username,
                                        :firstname => entry[auth_source.attr_firstname].first.to_s,
                                        :lastname => entry[auth_source.attr_lastname].first.to_s,
                                        :mail => entry[auth_source.attr_mail].first.to_s,
                                        :language => Setting.default_language,
                                        :mail_notification => Setting.default_notification_option,
                                        :auth_source_id => auth_source.id } )
            end
          end
        end
        (new_user && new_user.new_record?) ? nil : new_user
      end


      def do_login(user)
        if user.is_a?(User)
          start_user_session(user)
          user.update_attribute(:last_login_on, Time.now)
        else
          return nil
        end
      end

      def tfa_logout
        if User.current.logged?
          if User.current.tfa_login && (User.current.logout_time.nil? || User.current.login_expired?)
            logout_user
            return
          end
        end
      end

      def update_autologout_time
        if User.current.logged?
          if User.current.tfa_login
            unless User.current.login_expired?
              User.current.set_auto_logout_time
            end
          end
        end
      end

    end
  end
end