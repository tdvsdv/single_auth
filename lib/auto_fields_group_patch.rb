# issue_patch.rb

require_dependency 'project'
require_dependency 'principal'
require_dependency 'group'

module AutoFieldsGroupPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      has_many :ldapgroup, :class_name => 'Ldapgroup', :dependent=>:delete_all
    end

  end

  module ClassMethods   
    # Methods to add to the Issue class
  end

  module InstanceMethods
    # Methods to add to specific issue objects
  end
end

