class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :account, null: false, foreign_key: true
      t.string :username
      t.string :profile_pic_url
      t.json :preferences

      t.timestamps
    end
  end
end
