module SingleAuth
  module TokenPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
      end
    end

    module ClassMethods
      def self.find_token_by_user(user, action, validity_days=nil)
        action = action.to_s

        return nil unless action.present? && !user.nil

        token = Token.where(:action => action, :user_id => user.id).order(:created_on => :desc).first
        if token && (token.action == action) && token.user && token.user == user
          if validity_days.nil? || (token.created_on > validity_days.days.ago)
            token
          end
        end
      end

    end
  end
end