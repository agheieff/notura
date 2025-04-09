class CreateUserVocabularyEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :user_vocabulary_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :vocabulary_entry, null: false, foreign_key: true
      t.references :profile_language, null: false, foreign_key: true
      t.integer :proficiency_level, default: 0, null: false
      t.datetime :last_reviewed_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :next_review_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.jsonb :review_history, default: []
      t.text :notes
      t.jsonb :user_tags, default: []

      t.timestamps
      
      # Add unique constraint for user and vocabulary_entry
      t.index [:user_id, :vocabulary_entry_id], unique: true
      
      # Add indexes for common queries
      t.index :proficiency_level
      t.index :next_review_at
      t.index :user_tags, using: :gin
    end
  end
end