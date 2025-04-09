class Language < ApplicationRecord
  has_many :profile_languages, dependent: :destroy
  has_many :profiles, through: :profile_languages
  has_many :vocabulary_entries, dependent: :destroy
  
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :display_name, presence: true
  
  scope :available, -> { where(is_available: true) }
  scope :ordered_by_name, -> { order(:name) }
  
  # Find or initialize by code with default values
  def self.find_or_initialize_with_defaults(code, name = nil, display_name = nil)
    language = find_by(code: code)
    return language if language
    
    name ||= code.upcase
    display_name ||= name
    
    new(code: code, name: name, display_name: display_name)
  end
  
  # Get scraper words for this language
  def dictionary_words
    # Load dictionary scraper if needed
    require Rails.root.join('lib/dictionary_scraper/models/word')
    
    # Initialize repository
    repository = DictionaryScraper::WordRepository.new
    
    # Find words for this language
    repository.find_by_language(code)
  end
  
  # Import scraper words into vocabulary entries
  def import_dictionary_words
    words = dictionary_words
    return 0 if words.empty?
    
    imported = 0
    words.each do |word|
      entry = VocabularyEntry.from_scraper_word(word, id)
      if entry&.save
        imported += 1
      end
    end
    
    imported
  end
end