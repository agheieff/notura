require 'json'

module DictionaryScraper
  class WordRepository
    def initialize(storage_path = nil)
      @storage_path = storage_path || 'lib/dictionary_scraper/data/dictionary.json'
      @words = {}
      load_from_file if File.exist?(@storage_path)
    end
    
    def add(word)
      return false unless word.is_a?(Word) && word.text.present? && word.language_code.present?
      
      key = generate_key(word.text, word.language_code)
      @words[key] = word
      true
    end
    
    def get(text, language_code)
      key = generate_key(text, language_code)
      @words[key]
    end
    
    def all
      @words.values
    end
    
    def find_by_language(language_code)
      @words.values.select { |word| word.language_code == language_code }
    end
    
    def save
      exporter = JsonExporter.new(@storage_path)
      exporter.export(@words)
    end
    
    def load_from_file
      return unless File.exist?(@storage_path)
      
      json_data = JSON.parse(File.read(@storage_path))
      json_data.each do |key, word_data|
        word_data = word_data.transform_keys(&:to_sym)
        @words[key] = Word.new(word_data)
      end
    end
    
    private
    
    def generate_key(text, language_code)
      "#{language_code}:#{text.downcase}"
    end
  end
end