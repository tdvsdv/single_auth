require "net/http"
require "uri"

module SingleAuth
  module AccountControllerPatch

    def self.included(base)
      base.send(:include, ClassMethods)

      base.class_eval do
        include SingleAuthHelper

        alias_method_chain :login, :ldap_single_auth
        alias_method_chain :successful_authentication, :ldap_single_auth
      end
    end

    module ClassMethods

      def login_with_ldap_single_auth
        if (User.current.logged?)
          redirect_back_or_default(home_url)
          return
        end
        login_without_ldap_single_auth
      end

      def successful_authentication_with_ldap_single_auth(user)
        logger.debug("domain=#{request.domain}")
        logger.debug("ip=#{request.remote_ip}")
        logger.debug("whitelisted_domains=#{Setting.plugin_single_auth[:intranet_domains]}")

        enable_sms_auth = Setting.plugin_single_auth[:enable_sms_auth]
        intranet_domains = Setting.plugin_single_auth[:intranet_domains] || Redmine::Plugin::registered_plugins[:single_auth].settings[:default]['intranet_domains']
        ip_whitelist = Setting.plugin_single_auth[:ip_whitelist]
        user_groups_whitelist = Setting.plugin_single_auth[:user_groups_whitelist] || []
        debug_mode = Setting.plugin_single_auth[:enable_sms_debug_mode] || false

        if enable_sms_auth
          if user.respond_to?("user_phones")
            if (user.groups.map{|group| group.id.to_s} & user_groups_whitelist).count == 0
              unless intranet_domains.include?(request.domain) && ip_whitelist.include?(request.remote_ip)
                if (user.user_phones.any?)
                  token = Token.new(:user => user, :action => 'enter_sms_code')
                  if token.save
                    redirect_to :controller => 'account', :action => 'enter_sms_code', :token => token.value
                  end
                else
                  flash.now[:error] = l(:label_no_user_phone)
                end
              else
                successful_authentication_without_ldap_single_auth(user)
              end
            else
              successful_authentication_without_ldap_single_auth(user)
            end
          else
            successful_authentication_without_ldap_single_auth(user)
          end
        else
          successful_authentication_without_ldap_single_auth(user)
        end
      end

      def enter_sms_code
        token_valid_time = (Setting.plugin_single_auth[:token_valid_time] || Redmine::Plugin::registered_plugins[:single_auth].settings[:default][:token_valid_time]).to_i
        debug_mode = Setting.plugin_single_auth[:enable_sms_debug_mode] || false

        if params[:token]
          @token = Token.find_token('enter_sms_code', params[:token].to_s)
          (redirect_to(home_url); return) if @token.nil? || @token.try(:value) == '' || @token.expired?
          @user = @token.user

          if request.get?
            (redirect_to(home_url); return) unless Setting.plugin_single_auth[:enable_sms_auth]

            cell_phone = @user.user_phones.where(:phone_type => 'cell').first
            unless cell_phone.nil? || cell_phone.phone.empty?
              time = Time.now
              @user.otp_code(time)
              @time_left = @user.otp_time_left(time)

              if @user.otp_expired?(time) && !debug_mode
                send_sms_code(@user, cell_phone)
              end

              render 'account/enter_sms_code'
            else
              flash[:error] = l(:label_no_user_phone)
              redirect_to(signin_path)
            end
          elsif request.post?
            (redirect_to home_url; return) unless @user and @user.active?

            if params[:sms_code] && params[:sms_code].length > 0
              sms_code = params[:sms_code]
              if @user.authenticate_otp(sms_code)
                @token.destroy
                set_auto_logout_cookie(@user)

                logger.debug "SMS code authorization at #{Time.now} for user id=#{@user.id}, name=#{@user.firstname} #{@user.lastname}"
                logger.debug "User logged in from IP #{request.remote_ip} via domain \"#{request.domain}\""
                successful_authentication_without_ldap_single_auth(@user)
              else
                flash[:error] = l(:label_incorrect_sms_code)
                redirect_to :controller => 'account', :action => 'enter_sms_code', :token => @token.value
              end
            else
              flash[:error] = l(:label_no_sms_code)
              redirect_to :controller => 'account', :action => 'enter_sms_code', :token => @token.value
            end
          end
        else
          redirect_to(home_url)
          return
        end
      end

      def send_sms_code(user, cell_phone)
        username = Setting.plugin_single_auth[:sms_bot_login] || defaults['sms_bot_login']
        password = Setting.plugin_single_auth[:sms_bot_password] || defaults['sms_bot_password']
        phone_number = cell_phone.phone.gsub(/[\+\s]/, '')
        message = l(:label_sms_message, :code => user.otp_code)

        data = {:username => username, :password => password, :data => {:to => [phone_number], :body => message}}

        sms_domain = Setting.plugin_single_auth[:sms_domain] || defaults['sms_domain']
        sms_sub_url = Setting.plugin_single_auth[:sms_sub_url] || defaults['sms_sub_url']

        uri = URI.parse(sms_domain)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(sms_sub_url)
        request.body = data.to_param

        begin
          response = http.request(request)
        rescue
          flash[:error] = l(:label_no_user_phone)
          redirect_to(home_url)
        end

        if (response.code.to_i == 200)
          logger.debug "SMS service received request. Response body: #{response.body}"
        end
      end

    end
  end
end

