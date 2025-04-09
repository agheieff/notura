namespace :dictionary do
  desc "Import dictionary words from a JSON file"
  task :import, [:file_path] => :environment do |t, args|
    require_relative '../models/word'
    require_relative '../services/word_repository'
    require_relative '../exporters/json_exporter'
    
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
end