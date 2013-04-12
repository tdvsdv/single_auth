module SingleAuth
  module SingleAuth
    class Hooks  < Redmine::Hook::ViewListener
      render_on(:view_layouts_base_html_head, :partial => "hooks/single_auth/html_head")    
    end
  end
end
