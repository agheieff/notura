class VocabularyEntry < ApplicationRecord
  belongs_to :language
  has_many :user_vocabulary_entries, dependent: :destroy
  has_many :users, through: :user_vocabulary_entries
  
  validates :text, presence: true
  validates :word_class, presence: true
  
  # Store complex data structures in JSON columns
  serialize :translations, JSON
  serialize :ipa_transcriptions, JSON
  serialize :definitions, JSON
  serialize :examples, JSON
  serialize :synonyms, JSON
  serialize :antonyms, JSON
  serialize :word_forms, JSON
  serialize :related_words, JSON
  serialize :tags, JSON
  
  # Difficulty level (1-5)
  validates :difficulty, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true
  
  # Filter by language
  scope :by_language, ->(language_id) { where(language_id: language_id) }
  
  # Filter by word class (noun, verb, etc.)
  scope :by_word_class, ->(word_class) { where(word_class: word_class) }
  
  # Filter by difficulty level
  scope :by_difficulty, ->(level) { where(difficulty: level) }
  
  # Search by text
  scope :search_text, ->(query) { where("text ILIKE ?", "%#{query}%") }
  
  # Search by definition content
  scope :search_definition, ->(query) { where("definitions::text ILIKE ?", "%#{query}%") }
  
  # Search by tags
  scope :with_tags, ->(tags) { 
    tags = Array(tags)
    where("tags @> ?", tags.to_json)
  }
  
  # Import from DictionaryScraper::Word
  def self.from_scraper_word(scraper_word, language_id)
    # Find the language by code if language_id is not provided
    unless language_id
      language = Language.find_by(code: scraper_word.language_code)
      language_id = language&.id
    end
    
    return nil unless language_id
    
    vocabulary_entry = VocabularyEntry.find_or_initialize_by(
      text: scraper_word.text,
      language_id: language_id,
      word_class: scraper_word.word_class
    )
    
    vocabulary_entry.assign_attributes(
      translations: scraper_word.translations,
      ipa_transcriptions: scraper_word.ipa_transcriptions,
      definitions: scraper_word.definitions,
      examples: scraper_word.examples,
      synonyms: scraper_word.synonyms,
      antonyms: scraper_word.antonyms,
      etymology: scraper_word.etymology,
      word_forms: scraper_word.word_forms,
      related_words: scraper_word.related_words,
      frequency: scraper_word.frequency,
      difficulty: scraper_word.difficulty,
      tags: scraper_word.tags
    )
    
    vocabulary_entry
  end
  
  # Convert to a DictionaryScraper::Word object
  def to_scraper_word
    language_code = language&.code || 'unknown'
    
    DictionaryScraper::Word.new(
      text: text,
      language_code: language_code,
      word_class: word_class,
      translations: translations,
      ipa_transcriptions: ipa_transcriptions,
      definitions: definitions,
      examples: examples,
      synonyms: synonyms,
      antonyms: antonyms,
      etymology: etymology,
      word_forms: word_forms,
      related_words: related_words,
      frequency: frequency,
      difficulty: difficulty,
      tags: tags
    )
  end
end