module SingleAuth
  module AccountControllerPatch

    def self.included(base)
      base.send(:include, ClassMethods)

      base.class_eval do
        alias_method_chain :login, :ldap_single_auth
      end
    end

    module ClassMethods

      def login_with_ldap_single_auth
        if (User.current.logged?)
          redirect_back_or_default(home_url)
          return
        end
        login_without_ldap_single_auth
      end

    end
  end
end

