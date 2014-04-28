class GenerateSecretKeyForUsers < ActiveRecord::Migration
  def up
    if User.column_names.include?("otp_secret_key")
      User.all.each do |user|
        user.otp_secret_key = ROTP::Base32.random_base32
        puts "otp_secret_key = #{user.otp_secret_key}"
        user.save
      end
    end
  end

  def down
    User.update_all(:otp_secret_key => "")
  end
end

