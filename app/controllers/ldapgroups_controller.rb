class LdapgroupsController < ApplicationController
	unloadable
	before_filter :getSBData, :require_admin
 
	include SingleAuthHelper
	
  def index
	@ldapgroup=Ldapgroup.new
	#@Groups = Group.find(:all)
	#@LdapGroupsForRedmine=@ldapgroup.getLdapGroupsForRedmine
	#@Ldapgroups=Ldapgroup.find(:all, :order => "users.lastname DESC", :include => [:group])
	#flash[:notice] = @ppp
	#@auth_source.base_dn
  end

  def create
	@ldapgroup = Ldapgroup.new(params[:ldapgroup])
	
	if @ldapgroup.save
		flash[:notice] = l(:http_auth_create_apply)
		redirect_to :action => 'index' 
	else	
		#@Groups = Group.find(:all)
		#@LdapGroupsForRedmine=@ldapgroup.getLdapGroupsForRedmine
		#@Ldapgroups=Ldapgroup.find(:all)
		render :action => "index"
	end 	
  end
  
  def destroy
  @ldapgroup = Ldapgroup.find(params[:id])
  @ldapgroup.destroy
  flash[:notice] = l(:http_auth_create_delete)
  redirect_to :action => 'index' 
  end 
  
  private
  def getSBData
	@Groups = Group.find(:all, :order => "lastname ASC")
	
	auth_source=get_auth_source
	ldap=get_ldap_conn
	
	rm_group_attr=Setting.plugin_single_auth['ldap_rm_group_name_attr']
	filterA = Net::LDAP::Filter.eq('objectclass', 'group')
	#filterA = Net::LDAP::Filter.eq('objectguid', '\\01\\bd\\a3\\40\\da\\0f\\88\\4a\\87\\4b\\f9\\7c\\21\\be\\fa\\17')
	#filterA = Net::LDAP::Filter.eq('objectguid', '\40\A3\BD\01\0F\DA\4A\88\87\4B\F9\7C\21\BE\FA\17')
	#filterA = Net::LDAP::Filter.bineq('objectguid', ["40A3BD010FDA4A88874BF97C21BEFA17"].pack("H*"))
	#filterA = Net::LDAP::Filter.eq('objectguid', ['BF9679E70DE611D0A28500AA003049E2'].pack("H*"))
	filterB = Net::LDAP::Filter.pres(rm_group_attr)
	filter=filterA;
	#filter=filterA & filterB;
	@ldap_groups_for_redmine=[]
	ldap.search(:base => auth_source.base_dn, :filter => filter) do |entry|
			@ldap_groups_for_redmine.push([entry['cn'][0].to_s, entry.objectGUID.first.unpack("H*").first.to_s])
		end
		
	@ldap_groups_for_redmine=@ldap_groups_for_redmine.sort_by{|e| e[0]};

	@ldap_groups=Ldapgroup.find(:all, :order => "users.lastname ASC, ldapgroups.ldap_group_name ASC", :include => [:group])  
  end 
end
