class AddOtpTimeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :otp_time, :datetime
  end
end