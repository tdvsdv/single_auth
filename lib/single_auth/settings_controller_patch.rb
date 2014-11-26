module SingleAuth
  module SettingsControllerPatch
    unloadable

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :plugin, :single_auth
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def plugin_with_single_auth
        plugin_without_single_auth
        if request.post? && @plugin.id == 'single_auth'
          token_valid_time = params[:settings][:token_valid_time]
          redef_without_warning(ROTP, :DEFAULT_INTERVAL, token_valid_time.to_i)
        end
      end
    end

  end
end

