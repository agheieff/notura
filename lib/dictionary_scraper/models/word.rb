module DictionaryScraper
  class Word
    attr_reader :text, :language_code, :word_class, :translations, :ipa_transcriptions,
                :definitions, :examples, :synonyms, :antonyms, :etymology,
                :word_forms, :related_words, :frequency, :difficulty, :tags
    
    def initialize(attributes = {})
      @text = attributes[:text]
      @language_code = attributes[:language_code]
      @word_class = attributes[:word_class] # noun, verb, adjective, etc.
      @translations = attributes[:translations] || {} # { "en" => ["word1", "word2"], "fr" => ["mot1", "mot2"] }
      @ipa_transcriptions = attributes[:ipa_transcriptions] || [] # Multiple possible pronunciations
      @definitions = attributes[:definitions] || [] # List of definition strings or objects
      @examples = attributes[:examples] || [] # Example sentences using the word
      @synonyms = attributes[:synonyms] || []
      @antonyms = attributes[:antonyms] || []
      @etymology = attributes[:etymology] # Word origin information
      @word_forms = attributes[:word_forms] || {} # Flexible structure for all possible forms
      @related_words = attributes[:related_words] || [] # Derived words, compounds, etc.
      @frequency = attributes[:frequency] # How common the word is (can be a rank or score)
      @difficulty = attributes[:difficulty] # Learning difficulty rating (1-5)
      @tags = attributes[:tags] || [] # Additional classifications (formal, slang, technical, etc.)
    end
    
    def to_h
      {
        text: @text,
        language_code: @language_code,
        word_class: @word_class,
        translations: @translations,
        ipa_transcriptions: @ipa_transcriptions,
        definitions: @definitions,
        examples: @examples,
        synonyms: @synonyms,
        antonyms: @antonyms,
        etymology: @etymology,
        word_forms: @word_forms,
        related_words: @related_words,
        frequency: @frequency,
        difficulty: @difficulty,
        tags: @tags
      }
    end
    
    def to_json(*args)
      to_h.to_json(*args)
    end
    
    def add_translation(language_code, translation)
      @translations[language_code] ||= []
      @translations[language_code] << translation unless @translations[language_code].include?(translation)
    end
    
    def add_example(example)
      @examples << example unless @examples.include?(example)
    end
    
    # Add a word form with grammatical features
    # e.g., add_form("indicative.present.1sg", "amo")
    # or add_form({tense: "present", mood: "indicative", person: 1, number: "singular"}, "amo")
    def add_form(features, form_text)
      if features.is_a?(String)
        # Handle dot notation - convert "indicative.present.1sg" to nested hash
        parts = features.split('.')
        @word_forms[parts.first] ||= {}
        current = @word_forms[parts.first]
        
        parts[1..-2].each do |part|
          current[part] ||= {}
          current = current[part]
        end
        
        current[parts.last] = form_text
      elsif features.is_a?(Hash)
        # Handle feature hash - convert {tense: "present", mood: "indicative"...} to form
        feature_key = features.sort.map { |k, v| "#{k}:#{v}" }.join('.')
        feature_hash = features.dup
        
        # Start with the primary classification (usually mood or case)
        primary = feature_hash.delete(primary_feature_for_word_class)
        @word_forms[primary] ||= {}
        current = @word_forms[primary]
        
        # Handle remaining features hierarchically
        secondary_features_for_word_class.each do |feature|
          next unless feature_hash.key?(feature)
          value = feature_hash.delete(feature)
          current[value] ||= {}
          current = current[value]
        end
        
        # Any remaining features become part of the key
        if feature_hash.any?
          key = feature_hash.sort.map { |k, v| "#{k}:#{v}" }.join('.')
          current[key] = form_text
        else
          # Use a default key if we've used all features
          current["form"] = form_text
        end
      end
    end
    
    def get_form(features)
      if features.is_a?(String)
        # Handle dot notation
        parts = features.split('.')
        return nil if parts.empty?
        
        current = @word_forms
        parts.each do |part|
          return nil unless current.is_a?(Hash) && current.key?(part)
          current = current[part]
        end
        
        current
      elsif features.is_a?(Hash)
        # Find form by feature hash
        # This is more complex and would need to traverse based on the word class's feature hierarchy
        # For simplicity, we'll convert to dot notation
        feature_key = features.sort.map { |k, v| "#{k}:#{v}" }.join('.')
        get_form(feature_key)
      end
    end
    
    private
    
    def primary_feature_for_word_class
      case @word_class
      when 'verb'
        :mood
      when 'noun', 'pronoun', 'adjective', 'participle', 'gerund'
        :case
      else
        :form
      end
    end
    
    def secondary_features_for_word_class
      case @word_class
      when 'verb'
        [:tense, :person, :number]
      when 'noun', 'pronoun'
        [:number]
      when 'adjective', 'participle'
        [:gender, :number]
      when 'gerund'
        [:case, :number]
      else
        []
      end
    end
  end
end