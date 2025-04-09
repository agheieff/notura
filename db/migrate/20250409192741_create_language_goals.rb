class CreateLanguageGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :language_goals do |t|
      t.references :profile_language, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true
      t.integer :target_level
      t.date :target_date

      t.timestamps
    end
  end
end
