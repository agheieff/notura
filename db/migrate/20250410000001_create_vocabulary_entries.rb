class CreateVocabularyEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :vocabulary_entries do |t|
      t.references :language, null: false, foreign_key: true
      t.string :text, null: false
      t.string :word_class, null: false
      t.jsonb :translations, default: {}
      t.jsonb :ipa_transcriptions, default: []
      t.jsonb :definitions, default: []
      t.jsonb :examples, default: []
      t.jsonb :synonyms, default: []
      t.jsonb :antonyms, default: []
      t.text :etymology
      t.jsonb :word_forms, default: {}
      t.jsonb :related_words, default: []
      t.integer :frequency
      t.integer :difficulty
      t.jsonb :tags, default: []

      t.timestamps
      
      # Add unique constraint for language, text, and word_class
      t.index [:language_id, :text, :word_class], unique: true
      
      # Add indexes for common queries
      t.index :text
      t.index :word_class
      t.index :difficulty
      t.index :tags, using: :gin
    end
  end
end