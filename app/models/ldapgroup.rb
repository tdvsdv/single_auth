class Ldapgroup < ActiveRecord::Base
  unloadable
  belongs_to :group, :class_name => 'Group', :foreign_key => 'group_id'
  validates_presence_of :group_id
  validates_presence_of :ldap_group_name
  validates_uniqueness_of :group_id, :scope => :ldap_group_name, :message => l(:http_auth_uniqueness)
  
 	
 end
