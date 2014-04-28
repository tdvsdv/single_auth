module SingleAuth
  module ObjectPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
      end
    end

    module InstanceMethods
      def def_if_not_defined(mod, const, value)
        mod = mod.is_a?(Module) ? self : self.class
        mod.const_set(const, value) unless mod.const_defined?(const)
      end

      def redef_without_warning(mod, const, value)
        mod = mod.is_a?(Module) ? mod : mod.class
        mod.send(:remove_const, const) if mod.const_defined?(const)
        mod.const_set(const, value)
      end
    end
  end
end