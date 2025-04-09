module DictionaryScraper
  class FormRegistry
    # Registry of grammatical features by language and word class
    @feature_definitions = {}
    
    class << self
      attr_reader :feature_definitions
      
      # Register features for a language and word class
      # Example:
      #   FormRegistry.register('es', 'verb', {
      #     mood: [:indicative, :subjunctive, :imperative],
      #     tense: [:present, :preterite, :imperfect, :future, :conditional],
      #     person: [1, 2, 3],
      #     number: [:singular, :plural]
      #   })
      def register(language_code, word_class, features)
        @feature_definitions[language_code] ||= {}
        @feature_definitions[language_code][word_class.to_sym] = features
      end
      
      # Get features for a language and word class
      def features_for(language_code, word_class)
        return {} unless @feature_definitions[language_code]
        @feature_definitions[language_code][word_class.to_sym] || {}
      end
      
      # Get word classes for a language
      def word_classes_for(language_code)
        return [] unless @feature_definitions[language_code]
        @feature_definitions[language_code].keys
      end
      
      # Get possible values for a specific feature
      def values_for_feature(language_code, word_class, feature)
        features = features_for(language_code, word_class)
        features[feature.to_sym] || []
      end
      
      # Check if a feature combination is valid
      def valid_feature_combination?(language_code, word_class, feature_hash)
        features = features_for(language_code, word_class)
        
        feature_hash.each do |feature, value|
          feature_values = features[feature.to_sym]
          return false unless feature_values&.include?(value)
        end
        
        true
      end
    end
  end
end