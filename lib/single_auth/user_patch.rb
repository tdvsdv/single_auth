require "active_model_otp"

module SingleAuth
  module UserPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_one_time_password
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def set_auto_logout_time
        logout_timeout = Setting.plugin_single_auth[:logout_timeout] || Redmine::Plugin::registered_plugins[:single_auth].settings[:default]['logout_timeout']
        self.logout_time = logout_timeout.to_i.seconds.from_now
        self.save
      end

      def login_expired?
        self.logout_time.utc <= Time.now.utc
      end
    end

  end
end