class CreateTopics < ActiveRecord::Migration[8.0]
  def change
    create_table :topics do |t|
      t.string :name
      t.references :parent, null: true, foreign_key: { to_table: :topics }
      t.integer :difficulty_level

      t.timestamps
    end
  end
end
