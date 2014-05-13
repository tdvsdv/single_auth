class AddOtpInfoToUser < ActiveRecord::Migration
  def change
    add_column :users, :tfa_login, :boolean
    add_column :users, :logout_time, :datetime
  end
end
