module ActiveModel
  module OneTimePassword
    extend ActiveSupport::Concern

    module ClassMethods
      def has_one_time_password(options = {})

        cattr_accessor :otp_column_name
        self.otp_column_name = (options[:code_column_name] || "otp_secret_key").to_s

        before_create { self.otp_column = ROTP::Base32.random_base32 }

        if respond_to?(:attributes_protected_by_default)
          def self.attributes_protected_by_default #:nodoc:
            super + [self.otp_column_name]
          end
        end
      end
    end

    def authenticate_otp(code, options = {})
      totp = ROTP::TOTP.new(self)
      verify = false
      if drift = options[:drift]
        verify = totp.verify_with_drift(code, drift)
      else
        verify = totp.verify(code)
      end
      verify
    end

    def otp_code(time = Time.now, padding = false)
      totp = ROTP::TOTP.new(self)
      code_expired = self.otp_expired?(time)
      code = totp.at(time, code_expired, padding)
      code
    end

    def otp_expired?(time = Time.now)
      totp = ROTP::TOTP.new(self)
      time_left = self.otp_time_left(time, totp.interval)
      code_expired = false
      if time_left <= 0 || time_left == totp.interval
        code_expired = true
      end
    end

    def otp_time_left(time, interval = nil)
      if interval.nil?
        totp = ROTP::TOTP.new(self)
        interval = totp.interval
      end
      unless self.otp_time.nil?
        interval - (time - self.otp_time)).to_i
      else
        interval
      end
    end

    def provisioning_uri(account = nil)
      account ||= self.email if self.respond_to?(:email)
      ROTP::TOTP.new(self).provisioning_uri(account)
    end

    def otp_column
      self.send(self.class.otp_column_name)
    end

    def otp_column=(attr)
      self.send("#{self.class.otp_column_name}=", attr)
    end

  end
end
