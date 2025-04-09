class AddUserRefToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_reference :accounts, :user, null: true, foreign_key: true
  end
end
