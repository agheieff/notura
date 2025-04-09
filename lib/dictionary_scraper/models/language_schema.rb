module DictionaryScraper
  class LanguageSchema
    # Registry of language-specific schemas for word forms
    @schemas = {}
    
    class << self
      attr_reader :schemas
      
      def register(language_code, schema)
        @schemas[language_code] = schema
      end
      
      def for_language(language_code)
        @schemas[language_code] || {}
      end
      
      def word_classes_for(language_code)
        schema = for_language(language_code)
        schema.keys
      end
      
      def forms_for(language_code, word_class)
        schema = for_language(language_code)
        schema[word_class.to_sym] || {}
      end
    end
  end
end