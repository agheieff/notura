class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :email
      t.integer :payment_details_id
      t.integer :subscription_details_id

      t.timestamps
    end
    add_index :accounts, :email, unique: true
  end
end
