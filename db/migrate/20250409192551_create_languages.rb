class CreateLanguages < ActiveRecord::Migration[8.0]
  def change
    create_table :languages do |t|
      t.string :code
      t.string :name
      t.string :display_name
      t.boolean :is_available

      t.timestamps
    end
    add_index :languages, :code, unique: true
  end
end
