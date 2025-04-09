namespace :dictionary do
  desc "Load all dictionary scraper functionality"
  task :setup => :environment do
    # Load all the files in the dictionary_scraper directory
    Dir[Rails.root.join('lib/dictionary_scraper/**/*.rb')].each { |file| require file }
  end

  desc "Import dictionary data from JSON file"
  task :import, [:file_path] => [:setup] do |t, args|
    file_path = args[:file_path] || 'lib/dictionary_scraper/data/word_import.json'
    
    unless File.exist?(file_path)
      puts "Error: File not found: #{file_path}"
      exit 1
    end
    
    puts "Importing dictionary data from #{file_path}..."
    
    begin
      json_data = JSON.parse(File.read(file_path))
      repository = DictionaryScraper::WordRepository.new
      
      imported = 0
      json_data.each do |word_text, word_data|
        # Convert string keys to symbols
        word_data = word_data.transform_keys(&:to_sym) if word_data.is_a?(Hash)
        
        # If the data structure doesn't include text and language_code, add them
        word_data[:text] ||= word_text if word_data.is_a?(Hash)
        
        # Skip entries without language code
        unless word_data[:language_code].present?
          puts "Skipping '#{word_text}': missing language_code"
          next
        end
        
        word = DictionaryScraper::Word.new(word_data)
        if repository.add(word)
          imported += 1
        end
      end
      
      repository.save
      puts "Successfully imported #{imported} words into the dictionary."
      
    rescue JSON::ParserError => e
      puts "Error parsing JSON file: #{e.message}"
      exit 1
    rescue => e
      puts "Error during import: #{e.message}"
      exit 1
    end
  end
  
  desc "Export dictionary data to JSON file"
  task :export, [:language_code, :file_path] => [:setup] do |t, args|
    language_code = args[:language_code]
    file_path = args[:file_path] || "lib/dictionary_scraper/data/export_#{language_code || 'all'}.json"
    
    puts "Exporting dictionary data to #{file_path}..."
    
    begin
      repository = DictionaryScraper::WordRepository.new
      
      words = if language_code.present?
                repository.find_by_language(language_code)
              else
                repository.all
              end
      
      if words.empty?
        puts "No words found#{language_code ? " for language code '#{language_code}'" : ''}."
        exit 0
      end
      
      exporter = DictionaryScraper::JsonExporter.new(file_path)
      exporter.export(words)
      
      puts "Successfully exported #{words.count} words to #{file_path}."
      
    rescue => e
      puts "Error during export: #{e.message}"
      exit 1
    end
  end
  
  desc "List available languages in the dictionary"
  task :languages => [:setup] do
    repository = DictionaryScraper::WordRepository.new
    words = repository.all
    
    languages = words.map(&:language_code).uniq.sort
    
    if languages.empty?
      puts "No languages found in the dictionary."
    else
      puts "Available languages in the dictionary:"
      languages.each do |code|
        count = words.count { |word| word.language_code == code }
        puts "  - #{code}: #{count} words"
      end
    end
  end
  
  desc "Search for words in the dictionary"
  task :search, [:query, :language_code] => [:setup] do |t, args|
    query = args[:query]
    language_code = args[:language_code]
    
    if query.blank?
      puts "Error: No search query provided."
      exit 1
    end
    
    repository = DictionaryScraper::WordRepository.new
    words = repository.all
    
    # Filter by language if specified
    words = words.select { |word| word.language_code == language_code } if language_code.present?
    
    # Search by text match
    matches = words.select { |word| word.text.downcase.include?(query.downcase) }
    
    if matches.empty?
      puts "No matches found for '#{query}'#{language_code ? " in language '#{language_code}'" : ''}."
    else
      puts "Found #{matches.count} matches for '#{query}'#{language_code ? " in language '#{language_code}'" : ''}:"
      matches.each do |word|
        definition_preview = word.definitions.first.to_s.truncate(50) if word.definitions.any?
        puts "  - [#{word.language_code}] #{word.text} (#{word.word_class}): #{definition_preview}"
      end
    end
  end
end