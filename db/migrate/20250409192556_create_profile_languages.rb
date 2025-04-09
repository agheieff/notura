class CreateProfileLanguages < ActiveRecord::Migration[8.0]
  def change
    create_table :profile_languages do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :language, null: false, foreign_key: true
      t.json :proficiency_level
      t.boolean :is_native
      t.boolean :learning_active

      t.timestamps
    end
  end
end
