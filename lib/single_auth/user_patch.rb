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
    end

  end
end
