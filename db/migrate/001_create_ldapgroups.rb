class CreateLdapgroups < ActiveRecord::Migration
  def self.up
    create_table :ldapgroups do |t|
      t.references :group
      t.text :ldap_group_name
      t.timestamps
    end
  end

  def self.down
    drop_table :ldapgroups
  end
end
