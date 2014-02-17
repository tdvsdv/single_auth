module SingleAuth
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

        if current_user.nil? && !session[:logout_was] && request.env[Setting.plugin_single_auth['server_env_var']]
          current_user = try_login_by_remote_env(request.env[Setting.plugin_single_auth['server_env_var']])
        end

        current_user
      end

      def try_login_by_remote_env(remote_username)
        user = User.active.find_by_login remote_username
        # Rails.logger.debug "ggggg #{remote_username}"
        if user.nil?
          user = add_user_by_ldap_info(remote_username)
        end

        user if do_login(user)
      end

      def add_user_by_ldap_info(remote_username)
        auth_source = get_auth_source
        new_user = nil
        if auth_source && auth_source.onthefly_register?
          filter = Net::LDAP::Filter.eq(auth_source.attr_login, remote_username)
          ldap_connection = get_ldap_conn
          ldap_connection.search(:base => auth_source.base_dn, :filter => filter) do |entry|
            if AuthSourceLdap.respond_to?(:make_user_from_entry)
              # if ldap_users_sync method present - do it like a sync
              new_user = AuthSourceLdap.make_user_from_entry(auth_source, ldap_connection, entry)
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

    end
  end
end

