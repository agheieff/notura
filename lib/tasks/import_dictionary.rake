namespace :import do
  desc "Import dictionary data into vocabulary entries"
  task dictionary: :environment do
    # Load dictionary scraper
    require Rails.root.join('lib/dictionary_scraper/models/word')
    require Rails.root.join('lib/dictionary_scraper/services/word_repository')
    
    # Initialize repository
    repository = DictionaryScraper::WordRepository.new
    words = repository.all
    
    if words.empty?
      puts "No words found in dictionary repository."
      puts "Run 'rails dictionary:import[file_path]' to import dictionary data first."
      exit 0
    end
    
    # Group words by language
    words_by_language = words.group_by(&:language_code)
    
    puts "Found #{words.count} words across #{words_by_language.keys.count} languages."
    
    # Process each language
    words_by_language.each do |language_code, language_words|
      # Find or create language
      language = Language.find_by(code: language_code)
      
      unless language
        puts "Language '#{language_code}' not found in database. Creating..."
        language = Language.create(
          code: language_code,
          name: language_code.upcase,
          display_name: language_code.upcase,
          is_available: true
        )
        
        if language.persisted?
          puts "Created language: #{language.name} (#{language.code})"
        else
          puts "Failed to create language '#{language_code}': #{language.errors.full_messages.join(', ')}"
          next
        end
      end
      
      # Import words for this language
      puts "Importing #{language_words.count} words for language '#{language.name}'..."
      
      imported = 0
      language_words.each do |word|
        entry = VocabularyEntry.from_scraper_word(word, language.id)
        
        if entry&.save
          imported += 1
        else
          puts "  Failed to import word '#{word.text}': #{entry&.errors&.full_messages&.join(', ')}"
        end
      end
      
      puts "Imported #{imported}/#{language_words.count} words for language '#{language.name}'."
    end
    
    puts "Dictionary import complete."
  end
end