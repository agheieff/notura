module DictionaryScraper
  class JsonExporter
    def initialize(output_path)
      @output_path = output_path
      FileUtils.mkdir_p(File.dirname(@output_path)) unless Dir.exist?(File.dirname(@output_path))
    end
    
    def export(words)
      word_data = {}
      
      if words.is_a?(Array)
        words.each do |word|
          word_data[word.text] = word.to_h
        end
      elsif words.is_a?(Hash)
        word_data = words.transform_values { |word| word.is_a?(Word) ? word.to_h : word }
      else
        raise ArgumentError, "Expected Array or Hash of Word objects, got: #{words.class}"
      end
      
      File.open(@output_path, 'w') do |file|
        file.write(JSON.pretty_generate(word_data))
      end
      
      @output_path
    end
  end
end