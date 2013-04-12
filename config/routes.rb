=begin
ActionController::Routing::Routes.draw do |map|
  map.httpauthlogin 'httpauth-login', :controller => 'welcome'
  
  map.httpauthselfregister 'httpauth-selfregister/:action',
    :controller => 'registration', :action => 'autoregistration_form'
	
  map.resources :ldapgroups
end
=end
RedmineApp::Application.routes.draw do
	resources :ldapgroups
end